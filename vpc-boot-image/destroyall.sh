set -e
for step in 0[8-9]*.sh; do
  echo ">>> $step"
  ./$step
done
