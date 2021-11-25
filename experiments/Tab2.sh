
# small data
python -u pkpd_sim3_bias_generation.py --sim_id=sync1-p10 --control_sample=200 --control_c1=20 --train_step=25 --step=30 --seed=100
python -u pkpd_sim3_bias_generation.py --sim_id=sync1-p25 --control_sample=200 --control_c1=50 --train_step=25 --step=30 --seed=100


bash run_one_sim_bias.sh sync1-p10 1.5
bash run_one_sim_bias.sh sync1-p25 1.5


# bigger data

python -u pkpd_sim3_bias_generation.py --sim_id=sync6d-p10 --control_sample=1000 --control_c1=100 --train_step=25 --step=30 --seed=100
python -u pkpd_sim3_bias_generation.py --sim_id=sync6d-p25 --control_sample=1000 --control_c1=250 --train_step=25 --step=30 --seed=100


bash run_one_sim_bias.sh sync6d-p10 1.5
bash run_one_sim_bias.sh sync6d-p25 1.5

# summarize


bash summarize_one_sim.sh sync1-p10
bash summarize_one_sim.sh sync1-p25

bash summarize_one_sim.sh sync6d-p10
bash summarize_one_sim.sh sync6d-p25
