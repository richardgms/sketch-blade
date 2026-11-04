# Lote 2 de sons (04/11/2026): corta, nivela e converte os sons escolhidos pelo Richard
# para assets/sons/ (OGG Vorbis q4, mono, 44,1 kHz). Fontes, licencas e momentos: docs/sons.md.
# Os coracoes (raiva e vida baixa) sao gerados aqui mesmo (sem licenca de terceiros).
# Uso: python tools/sons_lote2.py [pasta de saida]   (padrao: assets/sons)
import os, sys, subprocess
import numpy as np

SR = 44100
S = "C:/Users/joalh/Videos/sons sketch blade/"
SAIDA = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "sons")
os.makedirs(SAIDA, exist_ok=True)

def carregar(f):
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", f, "-ac", "1", "-ar", str(SR), "-f", "f32le", "-"], capture_output=True).stdout
    return np.frombuffer(raw, np.float32).astype(np.float64)

def rms_ativo(x):
    hop = 441; n = max(len(x) // hop, 1)
    e = np.sqrt((x[:n * hop].reshape(n, hop) ** 2).mean(1)) + 1e-12
    db = 20 * np.log10(e); m = db > db.max() - 20
    return 20 * np.log10(np.sqrt((e[m] ** 2).mean()))

def cortar(x, ini=0.0, fim=None, fade=0.02, aparar=True):
    a = int(ini * SR); b = len(x) if fim is None else min(int(fim * SR), len(x))
    y = x[a:b].copy()
    if aparar:  # tira o silencio do comeco (deixa 5 ms antes do primeiro som)
        lim = np.abs(y).max() * 10 ** (-40 / 20)
        i0 = max(int(np.argmax(np.abs(y) > lim)) - int(0.005 * SR), 0)
        y = y[i0:]
    f = min(int(fade * SR), len(y))
    if f > 0:
        y[-f:] *= np.linspace(1, 0, f) ** 2
    y[:32] *= np.linspace(0, 1, 32)
    return y

def limitar(y, teto=0.95):
    """Limitador simples: segura so os picos (ataque ~instantaneo, soltura 40 ms)."""
    env = np.abs(y).copy(); r = np.exp(-1 / (0.040 * SR))
    for i in range(1, len(env)):
        env[i] = max(env[i], env[i - 1] * r)
    # olha 1 ms a frente para o ganho ja estar baixo quando o pico chega
    la = int(0.001 * SR); env = np.maximum(env, np.concatenate([env[la:], np.zeros(la)]))
    return y * np.minimum(1.0, teto / np.maximum(env, 1e-9))

def nivelar(y, alvo_db):
    # ate 6 passadas: ganho para o alvo e limitador nos picos (sons de clique tem pico alto)
    for _ in range(6):
        y = limitar(y * 10 ** ((alvo_db - rms_ativo(y)) / 20))
    return y

def salvar(nome, y):
    p = os.path.join(SAIDA, nome + ".ogg")
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "f32le", "-ar", str(SR), "-ac", "1", "-i", "-",
                    "-c:a", "libvorbis", "-q:a", "4", p], input=y.astype(np.float32).tobytes(), check=True)
    print(f"{nome:16s} {len(y) / SR:5.2f} s  rms ativo {rms_ativo(y):6.1f} dB  {os.path.getsize(p) / 1024:5.1f} KB")

def coracao(batidas, intervalo, forca=1.0):
    """Lub-dub sintetico: grave com harmonicos (tanh) para aparecer em alto-falante de celular."""
    dur = batidas * intervalo
    y = np.zeros(int(dur * SR) + int(0.3 * SR))
    def baque(t0, amp, f0):
        n = int(0.16 * SR); t = np.arange(n) / SR
        freq = f0 * (1 + 0.6 * np.exp(-t / 0.02))
        fase = 2 * np.pi * np.cumsum(freq) / SR
        env = (1 - np.exp(-t / 0.004)) * np.exp(-t / 0.055)
        s = np.tanh(2.5 * np.sin(fase)) * env * amp
        i = int(t0 * SR); y[i:i + n] += s[:len(y) - i]
    for k in range(batidas):
        t = k * intervalo
        baque(t, 1.0 * forca, 75.0)
        baque(t + 0.16, 0.6 * forca, 65.0)
    return y

def contagem_marimba():
    """Contagem aprovada em 04/11: nota original no 3-2-1, acorde agudo no JA."""
    mar = cortar(carregar(S + "01 gota de tinta/marimba tick.wav"), fade=0.02)
    bipe = nivelar(mar, -15.0)
    ja = np.zeros(len(mar) + 10)
    for semitons, ganho in ((12, 1.0), (7, 0.7), (0, 0.5)):
        passo = 2 ** (semitons / 12)
        indices = np.arange(0, len(mar) - 1, passo)
        nota = np.interp(indices, np.arange(len(mar)), mar)
        ja[:len(nota)] += ganho * nota
    ja = nivelar(cortar(ja, fade=0.03, aparar=False), -15.0)
    return {"contagem_bipe": bipe, "contagem_ja": ja}

def sons():
    q = {}
    # gota de tinta: atual (Kenney drop_002) + 3 variacoes do mesmo pacote (CC0)
    for i, f in zip((2, 3, 4), ("drop_001", "drop_003", "drop_004")):
        q[f"gota_{i}"] = nivelar(cortar(carregar(S + f"01 gota de tinta/kenney interface sounds (CC0)/{f}.ogg")), -12.1)
    # monstro morre: atual (squish_02) + 5 variacoes do mesmo pacote (EZduzziteh, CC0);
    # squishpop e squishsplat_impact sairam a pedido do Richard (04/11)
    for i, f in enumerate(("squish_01_0", "squish_03", "squish_04", "squish_05", "squish_06"), start=2):
        q[f"morte_{i}"] = nivelar(cortar(carregar(S + f"02 monstro morre/opengameart squish (CC0, EZduzziteh)/{f}.mp3"), fade=0.05), -19.9)
    # caneta toma dano: 3 quedas de caneta do mesmo arquivo (krb21, CC0)
    pen = carregar(S + "03 caneta toma dano/tossing-pen-down.wav")
    for i, t in enumerate((3.73, 11.76, 16.47), start=1):
        q[f"dano_{i}"] = nivelar(cortar(pen, t - 0.02, t + 0.5, fade=0.15), -16.0)
    q["pagina"] = nivelar(cortar(carregar(S + "05 virar pagina/page-turned.wav"), fade=0.08), -17.6)
    q["folha"] = nivelar(cortar(carregar(S + "06 clique de botao/paper-slide.wav"), 0.0, 0.38, fade=0.08), -19.0)
    q["clique"] = nivelar(cortar(carregar(S + "06 clique de botao/retractable-pen-click-in-out.wav"), 0.0, 0.2, fade=0.03), -16.0)
    q["erro"] = nivelar(cortar(carregar(S + "07 clique de erro/locked.wav"), fade=0.03), -14.0)
    growl = cortar(carregar(S + "08 chefe surge/deep-growl.wav"), fade=0.0)
    sub = cortar(carregar(S + "08 chefe surge/sub-drop.wav"), fade=0.0)
    n = int(1.9 * SR); mix = np.zeros(n)
    mix[:min(n, len(growl))] += growl[:n]; mix[:min(n, len(sub))] += 0.7 * sub[:n]
    q["chefe_surge"] = nivelar(cortar(mix, fade=0.35, aparar=False), -15.1)
    q["chefe_ataque"] = nivelar(cortar(carregar(S + "09 chefe ataque e mergulho/monster-snarl.wav"), 0.0, 1.3, fade=0.3), -18.7)
    q["rasante"] = nivelar(cortar(carregar(S + "09 chefe ataque e mergulho/heavy-swoosh.wav"), fade=0.08), -20.0)
    q["asas"] = nivelar(cortar(carregar(S + "09 chefe ataque e mergulho/paper-wings-flap.wav"), fade=0.08), -22.0)
    q["cuspe"] = nivelar(cortar(carregar(S + "11 tiros dos chefes/spit.wav"), fade=0.02), -22.0)
    q["krw"] = nivelar(cortar(carregar(S + "11 tiros dos chefes/pre-split-vocal-creepy-krw.wav"), fade=0.02), -19.0)
    q["vitoria"] = nivelar(cortar(carregar(S + "12 vitoria/suno - vitoria stinger guitarra.wav"), 0.0, 2.0, fade=0.5), -16.6)
    der = carregar(S + "13 derrota/suno - derrota stinger guitarra.wav")
    q["derrota"] = nivelar(cortar(der, fade=0.4), -17.3)  # o arquivo inteiro (os dois sons juntos), a pedido do Richard
    q["roleta"] = nivelar(cortar(carregar(S + "15 roleta/roulette-wheel-spin-loop.wav"), 0.0, 1.0, fade=0.4), -20.0)
    q["cura"] = nivelar(cortar(carregar(S + "16 descanso/suno - cura power-up blip.wav"), 0.0, 1.35, fade=0.25), -17.0)
    q["bonus"] = nivelar(cortar(carregar(S + "17 bonus do anuncio/bling.wav"), 0.0, 1.3, fade=0.2), -17.0)
    q["carta"] = nivelar(cortar(carregar(S + "18 subir de nivel e cartas/kenney interface sounds (CC0)/confirmation_002.ogg")), -14.0)
    q["compra"] = nivelar(cortar(carregar(S + "19 loja e compra/kenney rpg audio (CC0)/handleCoins.ogg"), fade=0.08), -16.0)
    q["check"] = nivelar(cortar(carregar(S + "20 missao e recompensa diaria/pencil_check_mark.wav"), 0.0, 0.45, fade=0.05), -15.0)
    q["ziper"] = nivelar(cortar(carregar(S + "21 estojo/ziper.wav"), 0.0, 1.1, fade=0.1), -17.0)
    q["pausa"] = nivelar(cortar(carregar(S + "22 pausa e retomar/pause.mp3"), 0.0, 0.3, fade=0.05), -15.0)
    q["retomar"] = nivelar(cortar(carregar(S + "22 pausa e retomar/unpause.mp3"), 0.0, 0.3, fade=0.05), -15.0)
    q["aviso"] = nivelar(cortar(carregar(S + "23 aviso de atualizacao/kenney interface sounds (CC0)/glass_001.ogg")), -15.0)
    q.update(contagem_marimba())
    q["coracao_rapido"] = nivelar(coracao(4, 60 / 118), -15.0)       # raiva do chefe: 4 batidas no andamento da musica do chefe
    lento = coracao(1, 0.9)[:int(0.9 * SR)]                            # vida baixa: 1 batida a cada 0,9 s, em loop
    q["coracao_lento"] = nivelar(lento, -22.0)
    return q

if __name__ == "__main__":
    for nome, y in sons().items():
        salvar(nome, y)
