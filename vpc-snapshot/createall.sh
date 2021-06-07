set -e
for step in 0[0-7]*.sh; do
  echo ">>> $step"
  ./$step
done
