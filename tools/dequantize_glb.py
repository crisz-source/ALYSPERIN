"""Remove KHR_mesh_quantization de um .glb (Godot 4.7 não lê a extensão).

Converte todo accessor de malha com inteiro normalizado/não normalizado para
float32 e o grava num bufferView novo no fim do buffer binário. Só biblioteca
padrão. Uso: python -I dequantize_glb.py entrada.glb saida.glb
"""
import json
import struct
import sys

COMP = {5120: ("b", 1, 127.0), 5121: ("B", 1, 255.0), 5122: ("h", 2, 32767.0),
        5123: ("H", 2, 65535.0), 5125: ("I", 4, None), 5126: ("f", 4, None)}
NCOMP = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}


def main(src: str, dst: str) -> None:
    data = open(src, "rb").read()
    clen = struct.unpack("<I", data[12:16])[0]
    j = json.loads(data[20:20 + clen])
    bin_off = 20 + clen
    blen = struct.unpack("<I", data[bin_off:bin_off + 4])[0]
    binary = bytearray(data[bin_off + 8:bin_off + 8 + blen])

    targets = set()
    for mesh in j["meshes"]:
        for prim in mesh["primitives"]:
            targets.update(prim["attributes"].values())
            for t in prim.get("targets", []):
                targets.update(t.values())
    converted = 0
    for idx in sorted(targets):
        acc = j["accessors"][idx]
        if acc["componentType"] == 5126:
            continue
        fmt, size, norm = COMP[acc["componentType"]]
        n = NCOMP[acc["type"]]
        bv = j["bufferViews"][acc["bufferView"]]
        stride = bv.get("byteStride") or size * n
        base = bv.get("byteOffset", 0) + acc.get("byteOffset", 0)
        out = []
        for i in range(acc["count"]):
            vals = struct.unpack_from("<%d%s" % (n, fmt), binary, base + i * stride)
            if acc.get("normalized"):
                vals = [max(v / norm, -1.0) for v in vals]
            out.extend(float(v) for v in vals)
        while len(binary) % 4:
            binary.append(0)
        off = len(binary)
        binary += struct.pack("<%df" % len(out), *out)
        j["bufferViews"].append({"buffer": 0, "byteOffset": off, "byteLength": len(out) * 4})
        acc["bufferView"] = len(j["bufferViews"]) - 1
        acc["byteOffset"] = 0
        acc["componentType"] = 5126
        acc.pop("normalized", None)
        if "min" in acc:
            acc["min"] = [min(out[c::n]) for c in range(n)]
            acc["max"] = [max(out[c::n]) for c in range(n)]
        converted += 1

    for key in ("extensionsUsed", "extensionsRequired"):
        if key in j:
            j[key] = [e for e in j[key] if e != "KHR_mesh_quantization"]
            if not j[key]:
                del j[key]
    while len(binary) % 4:
        binary.append(0)
    j["buffers"][0]["byteLength"] = len(binary)

    js = json.dumps(j, separators=(",", ":")).encode()
    js += b" " * ((4 - len(js) % 4) % 4)
    total = 12 + 8 + len(js) + 8 + len(binary)
    with open(dst, "wb") as fh:
        fh.write(struct.pack("<4sII", b"glTF", 2, total))
        fh.write(struct.pack("<I4s", len(js), b"JSON") + js)
        fh.write(struct.pack("<I4s", len(binary), b"BIN\x00") + binary)
    print("accessors convertidos:", converted, "bytes:", total)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
