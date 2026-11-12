"""Envia um AAB para uma faixa de teste do Google Play (API Android Publisher).

Uso:
  python tools/enviar_play.py --listar
  python tools/enviar_play.py <arquivo.aab> --faixa <nome> --notas "texto" [--validar]

--listar   mostra as faixas e as versões em cada uma (não muda nada).
--validar  faz tudo e só valida no fim, sem publicar (teste seguro).
Chave da conta de serviço: Documentos/keys/sketchblade-play-api.json (fora do git).
A conta só tem permissão para faixas de teste: produção é bloqueada pelo Google.
"""
import argparse
import os
import sys

import requests
from google.auth.transport.requests import Request
from google.oauth2 import service_account

PACOTE = "com.richardgms.sketchblade"
CHAVE = os.path.join(os.path.expanduser("~"), "Documentos", "keys", "sketchblade-play-api.json")
API = f"https://androidpublisher.googleapis.com/androidpublisher/v3/applications/{PACOTE}"
UPLOAD = f"https://androidpublisher.googleapis.com/upload/androidpublisher/v3/applications/{PACOTE}"


def sessao() -> requests.Session:
    cred = service_account.Credentials.from_service_account_file(
        CHAVE, scopes=["https://www.googleapis.com/auth/androidpublisher"])
    cred.refresh(Request())
    s = requests.Session()
    s.headers["Authorization"] = f"Bearer {cred.token}"
    return s


def checar(r: requests.Response) -> dict:
    if not r.ok:
        sys.exit(f"Erro {r.status_code}: {r.text[:800]}")
    return r.json() if r.text else {}


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("aab", nargs="?")
    ap.add_argument("--faixa")
    ap.add_argument("--notas", default="")
    ap.add_argument("--listar", action="store_true")
    ap.add_argument("--validar", action="store_true")
    a = ap.parse_args()

    s = sessao()
    edit = checar(s.post(f"{API}/edits"))["id"]
    try:
        if a.listar:
            for t in checar(s.get(f"{API}/edits/{edit}/tracks")).get("tracks", []):
                rel = [(r.get("name"), r.get("versionCodes"), r.get("status")) for r in t.get("releases", [])]
                print(t["track"], rel)
            return
        if not (a.aab and a.faixa):
            sys.exit("Informe o .aab e --faixa (veja as faixas com --listar).")
        if a.faixa == "production":
            sys.exit("Produção não: este script é só para faixas de teste.")
        tam = os.path.getsize(a.aab) / 1e6
        print(f"Enviando {os.path.basename(a.aab)} ({tam:.1f} MB)...")
        with open(a.aab, "rb") as f:
            b = checar(s.post(f"{UPLOAD}/edits/{edit}/bundles", params={"uploadType": "media"},
                              data=f, headers={"Content-Type": "application/octet-stream"}, timeout=900))
        codigo = str(b["versionCode"])
        print(f"Bundle aceito: código {codigo}")
        release = {"versionCodes": [codigo], "status": "completed"}
        if a.notas:
            release["releaseNotes"] = [{"language": "pt-BR", "text": a.notas}]
        checar(s.put(f"{API}/edits/{edit}/tracks/{a.faixa}", json={"track": a.faixa, "releases": [release]}))
        if a.validar:
            checar(s.post(f"{API}/edits/{edit}:validate"))
            print("Validado (nada publicado).")
        else:
            checar(s.post(f"{API}/edits/{edit}:commit"))
            print(f"Publicado na faixa '{a.faixa}': código {codigo}.")
            edit = None
    finally:
        if edit:
            s.delete(f"{API}/edits/{edit}")


if __name__ == "__main__":
    main()
