# usage: run_one_sim.sh sync1 25 30 200 200
sim_id=$1
train_step=$2
step=$3
control_sample=$4
treatment_sample=$5
tau=$6
hidden_confounder=$7

echo ${sim_id}
echo ${train_step}
echo ${step}
echo ${control_sample}
echo ${treatment_sample}
echo ${tau}

python -u pkpd_sim3_data_generation.py --sim_id=${sim_id} --train_step=${train_step} --step=${step} --control_sample=${control_sample} --treatment_sample=${treatment_sample} --seed=100

python -u pkpd_sim3_model_training.py --sim_id=${sim_id} --seed=100 --model_id=-prognostic-linear --reduced_fine_tune=True --tau=${tau} --lam_prognostic=1 --pretrain_Y=True --itr=10 --linear_decoder=True  > models/${sim_id}-prognostic_linear.txt
python -u pkpd_sim3_model_training.py --sim_id=${sim_id} --seed=100 --model_id=-prognostic-none --reduced_fine_tune=True --tau=${tau} --lam_prognostic=0 --pretrain_Y=False --itr=10 --linear_decoder=True  > models/${sim_id}-prognostic_none.txt
python -u pkpd_sim3_model_training.py --sim_id=${sim_id} --seed=100 --model_id=-prognostic-recon --reduced_fine_tune=True --lam_recon=0 --pretrain_Y=True --itr=2 --linear_decoder=True  > models/${sim_id}-prognostic_recon.txt

Rscript pkpd_synth_control.R ${sim_id} 100 > models/${sim_id}-sc.txt
Rscript pkpd_1nn.R ${sim_id} 100 > models/${sim_id}-1nn.txt
Rscript pkpd-mc-nnm.R ${sim_id} 100 > models/${sim_id}-nnm.txt

python -u pkpd_sim3_cfr.py --sim_id=${sim_id} --seed=100 --lam_dist=0.1 > models/${sim_id}_cfr.txt
python -u clair_benchmark.py --sim_id=${sim_id} --seed=100 --model_name=CRN > models/${sim_id}-CRN.txt
python -u clair_benchmark.py --sim_id=${sim_id} --seed=100 --model_name=RMSN > models/${sim_id}-RMSN.txt
python -u gp_benchmark.py --sim_id=${sim_id}  > models/${sim_id}-gp.txt

# This takes a long time
python -u pkpd_rsc.py --sim_id=${sim_id} --seed=100 > models/${sim_id}-rsc.txt
