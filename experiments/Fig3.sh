### omitted variable experiment

# one omitted variable
python -u pkpd_sim3_data_generation.py --sim_id=sync1-p50-h1 --train_step=25 --step=30 --seed=100 --hidden_confounder=1
bash run_one_sim_bias.sh sync1-p50-h1 1.5
bash summarize_one_sim.sh sync1-p50-h1


# more omitted variables

python -u pkpd_sim3_data_generation.py --sim_id=sync1-p50-h2 --train_step=25 --step=30 --seed=100 --hidden_confounder=2
bash run_one_sim_bias.sh sync1-p50-h2 1.5
bash summarize_one_sim.sh sync1-p50-h2

