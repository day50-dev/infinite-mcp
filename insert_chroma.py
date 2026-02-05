#!/usr/bin/env python3 
from tqdm import tqdm
from pathlib import Path
import chromadb
import os
import sys
import torch
import magic
import html2text
import chardet
import signal
import re
import spacy
from sentence_transformers import SentenceTransformer

model = None #common.model
#client = chromadb.PersistentClient(path="./chroma_db")
#collection = client.get_or_create_collection(name="documents")
BATCH_SIZE = 1

def detect_encoding(file_path):
      with open(file_path, 'rb') as f:
          raw_data = f.read()
      result = chardet.detect(raw_data)
      return result['encoding']

def move_batch(amount):
    global BATCH_SIZE
    BATCH_SIZE += amount
    BATCH_SIZE = max(1, BATCH_SIZE)
    print(f"\n*** New batch size {BATCH_SIZE}", flush=True)

def _increase_batch(signum, frame):
    move_batch(1)

def _decrease_batch(signum, frame):
    move_batch(-1)

signal.signal(signal.SIGUSR1, _increase_batch)
signal.signal(signal.SIGUSR2, _decrease_batch)

counter = 0

def reader(config):
  lines = []
  encoding = detect_encoding(config) 
  with open(config, 'r', encoding=encoding, errors='replace') as f:
    lines = []
    for what in f.readlines():
      if "`" not in what:
        lines.append(what)
  return re.sub(r'\s+', ' ', " ".join(lines))

def getter(fp, path):
  config = Path(os.path.dirname(fp)) / path
  if not os.path.isfile(config):
    print(f"{fp} no {path}")
    return
  with open(config, 'r') as f:
    if f.read().strip() == "none":
      print(f"{config} bad json")

  return config

i = -1 
while True:
    texts = []
    configs = []
    onelines = []
    valid_paths = []
    metas = []
    while len(valid_paths) < BATCH_SIZE:
        i += 1
        #sys.stdout.write('.')
        #sys.stdout.flush()
        fp = sys.stdin.readline().strip()
        if not os.path.isfile(fp):
            break

        try:
            meta = getter(fp, "_meta-info.json")
            if not meta:
              print(f"?? {fp} meta_info")
              continue

            #config = getter(fp, "_mcp-config.json")
            #if not config:
            #  continue
            config=[]

            oneline = getter(fp, "_one-liner.json")
            if not oneline:
              print(f"!! {fp} one-liner")
              continue
            try_one = reader(oneline)
            if 'npx' in try_one:
              pass
            elif 'your' in try_one and 'program' in try_one:
              print(f"!? {try_one} {fp}")
              continue
            elif 'go", "run' in try_one:
              pass
            elif 'uv", "tool' in try_one:
              pass
            elif 'uvx' in try_one:
              pass
              #print(f".. {try_one} {fp}")
            else:
              print(f"!@ {try_one} {fp}")
              continue

            #configs.append(reader(config))
            onelines.append(try_one)
            metas.append(reader(meta))

            encoding = detect_encoding(fp) 
            with open(fp, 'r', encoding=encoding, errors='replace') as f:
                processed_text = f.read()
                texts.append(processed_text)
            valid_paths.append(str(fp))
        except Exception as e:
          print(f"{fp} => {e}")
    
    if len(texts) == 0:
        break

    if model == None:
      import common
      model = common.model
      client = chromadb.PersistentClient(path="./chroma_db")
      collection = client.get_or_create_collection(name="documents")
    try:
      with torch.no_grad():
          embeddings = model.encode(
              texts, 
              show_progress_bar=False,
              batch_size=len(texts),
              convert_to_numpy=True
          )
      
      torch.cuda.empty_cache()
      
      meta = []
      stubs = []
      for i in range(len(valid_paths)):
        stub = "/".join(valid_paths[i].split("/")[-3:-1])
        stubs.append(stub)
        #             'config': configs[i], 
        meta.append({'file_path': stub, 'meta': metas[i], 
                     'oneline': onelines[i] })

      try:
        collection.add(
            embeddings=embeddings.tolist(),
            documents=texts,
            ids=[j.replace('/', '_') for j in stubs],
            metadatas=meta
        )
      except Exception as ex:
        print(ex)
        pass

      torch.cuda.empty_cache()
      counter += 1

      if counter > 25:
        move_batch(1)
        counter = 0

    except RuntimeError as e:
      print(e)
      i -= BATCH_SIZE
      move_batch(-1)
      counter = 0
      continue

    except Exception as ex:
      print(ex)
