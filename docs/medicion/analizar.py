"""Resumen descriptivo de la ficha de cronometraje (sección 16.3).

Uso: python docs/medicion/analizar.py docs/medicion/ficha_cronometraje.csv
Solo usa la biblioteca estándar.
"""
import csv
import statistics
import sys
from collections import defaultdict


def main(path: str) -> None:
    tiempos = defaultdict(list)
    incidencias = defaultdict(lambda: [0, 0])
    sin_estado = defaultdict(int)

    with open(path, newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            if not row["minutos"]:
                continue
            clave = (row["tarea"], row["modalidad"])
            tiempos[clave].append(float(row["minutos"]))
            incidencias[row["modalidad"]][1] += 1
            if row["incidencia"].strip():
                incidencias[row["modalidad"]][0] += 1
            if row["estado_conocido"].strip().lower() in {"no", "false", "0"}:
                sin_estado[row["modalidad"]] += 1

    if not tiempos:
        print("Aún no hay mediciones registradas.")
        return

    print(f"{'tarea':<18}{'modalidad':<12}{'n':>4}{'mediana':>10}{'promedio':>10}{'desv.est':>10}")
    for (tarea, modalidad), v in sorted(tiempos.items()):
        sd = statistics.stdev(v) if len(v) > 1 else 0.0
        print(f"{tarea:<18}{modalidad:<12}{len(v):>4}{statistics.median(v):>10.2f}{statistics.mean(v):>10.2f}{sd:>10.2f}")

    for tarea in sorted({t for t, _ in tiempos}):
        m, p = tiempos.get((tarea, "manual")), tiempos.get((tarea, "plataforma"))
        if m and p:
            cambio = (statistics.median(p) - statistics.median(m)) / statistics.median(m) * 100
            print(f"Variación de la mediana en {tarea}: {cambio:+.1f} %")

    for modalidad, (inc, total) in incidencias.items():
        print(f"Incidencias {modalidad}: {inc}/{total} ({inc / total * 100:.1f} %); pedidos sin estado conocido: {sin_estado[modalidad]}")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "docs/medicion/ficha_cronometraje.csv")
