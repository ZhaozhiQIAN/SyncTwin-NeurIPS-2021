# Run all (non-real data) experiments.

cd "$(dirname "$0")/.."  # cd to repo root.
mkdir -p models
mkdir -p results



printf "\n=============== Runnung: Tab6.sh ===============\n\n"
bash experiments/Tab6.sh

printf "\n=============== Runnung: Fig3.sh ===============\n\n"
bash experiments/Fig3.sh

printf "\n=============== Runnung: Tab2.sh ===============\n\n"
bash experiments/Tab2.sh

printf "\n=============== Runnung: Tab5.sh ===============\n\n"
bash experiments/Tab5.sh

printf "\n=============== Runnung: Tab7.sh ===============\n\n"
bash experiments/Tab7.sh
