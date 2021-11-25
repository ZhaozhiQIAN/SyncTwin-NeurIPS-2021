# the first script to run

bash run_one_sim.sh sync1 25 30 200 200 1
bash run_one_sim.sh sync2 15 20 200 200 1
bash run_one_sim.sh sync3 45 50 200 200 1

bash run_one_sim.sh sync6d 25 30 1000 200 1.5
bash run_one_sim.sh sync7d 15 20 1000 200 1.5
bash run_one_sim.sh sync8d 45 50 1000 200 1.5

bash summarize_one_sim.sh sync1
bash summarize_one_sim.sh sync2
bash summarize_one_sim.sh sync3

bash summarize_one_sim.sh sync6d
bash summarize_one_sim.sh sync7d
bash summarize_one_sim.sh sync8d

cp Tab2_C3_MAE.txt Tab6_C2_MAE.txt
cp Tab2_C6_MAE.txt Tab6_C5_MAE.txt
