set -e
for step in 0*.sh; do
  echo ">>> $step"
  ./$step
done
