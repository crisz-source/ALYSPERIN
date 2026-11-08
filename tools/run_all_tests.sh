#!/bin/sh
# Roda todas as suítes de teste (headless) e mostra o resumo.
# Uso (Git Bash), na pasta do projeto:  GODOT=/caminho/do/Godot_console.exe sh tools/run_all_tests.sh
GODOT="${GODOT:-godot}"
total_p=0; total_f=0
for f in tools/tests/test*.gd; do
  out=$("$GODOT" --headless --path . --script tools/tests/run_test.gd -- "res://$f" 2>&1)
  res=$(echo "$out" | grep "RESULTADO")
  p=$(echo "$res" | sed -n 's/RESULTADO: \([0-9]*\) passaram, \([0-9]*\) falharam/\1/p')
  fl=$(echo "$res" | sed -n 's/RESULTADO: \([0-9]*\) passaram, \([0-9]*\) falharam/\2/p')
  if [ -z "$p" ]; then echo "!! $f sem resultado"; echo "$out" | grep -E "SCRIPT ERROR|Parse" | head -3; total_f=$((total_f+1)); continue; fi
  total_p=$((total_p+p)); total_f=$((total_f+fl))
  echo "$(basename $f): $p ok, $fl falha"
  echo "$out" | grep "^FAIL" | head -5
done
echo "TOTAL: $total_p ok, $total_f falha"
