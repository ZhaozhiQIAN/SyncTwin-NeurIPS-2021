# the first script to run

bash run_one_sim.sh sync1 25 30 200 200 1
bash run_one_sim.sh sync2 15 20 200 200 1
bash run_one_sim.sh sync3 45 50 200 200 1

bash run_one_sim.sh sync6d 25 30 1000 200 1.5
bash run_one_sim.sh sync7d 15 20 1000 200 1.5
bash run_one_sim.sh sync8d 45 50 1000 200 1.5


# ablate reconstruction loss
#for sim_id in sync1 sync2 sync3
#do
#    python -u pkpd_sim3_model_training.py --sim_id=${sim_id} --seed=100 --model_id=-prognostic-recon --reduced_fine_tune=True --lam_recon=0 --pretrain_Y=True --itr=2 --linear_decoder=True  > models/${sim_id}-prognostic_recon.txt
#done
#
#for sim_id in sync6d sync7d sync8d
#do
#    python -u pkpd_sim3_model_training.py --sim_id=${sim_id} --seed=100 --model_id=-prognostic-recon --reduced_fine_tune=True --lam_recon=0 --pretrain_Y=True --itr=2 --linear_decoder=True  > models/${sim_id}-prognostic_recon.txt
#done

# GP benchmark
#for sim_id in sync1 sync2 sync3 sync6d sync7d sync8d sync1-p10 sync1-p25 sync6d-p10 sync6d-p25 sync1-miss-0.3 sync1-miss-0.5 sync1-miss-0.7 sync6d-miss-0.3 sync6d-miss-0.5 sync6d-miss-0.7
#do
#    python -u gp_benchmark.py --sim_id=${sim_id}  > models/${sim_id}-gp.txt
#    echo ${sim_id} >> models/gp_MAE.txt
#    grep -E "MAE" models/${sim_id}-gp.txt | head -n 6 | tail -n 1  >> models/gp_MAE.txt
#done


# CFR-NET

#for sim_id in sync1 sync2 sync3 sync6d sync7d sync8d sync1-p10 sync1-p25 sync6d-p10 sync6d-p25 sync1-miss-0.3 sync1-miss-0.5 sync1-miss-0.7 sync6d-miss-0.3 sync6d-miss-0.5 sync6d-miss-0.7
#do
#    python -u pkpd_sim3_cfr.py --sim_id=${sim_id} --seed=100 --lam_dist=0.1 > models/${sim_id}_cfr.txt
#done




bash summarize_one_sim.sh sync1
bash summarize_one_sim.sh sync2
bash summarize_one_sim.sh sync3



bash summarize_one_sim.sh sync6d
bash summarize_one_sim.sh sync7d
bash summarize_one_sim.sh sync8d

# additional


#for sim_id in sync1 sync2 sync3 sync6d sync7d sync8d
#do
# python -u clair_benchmark.py --sim_id=${sim_id} --seed=100 --model_name=CRN > models/${sim_id}-CRN.txt &
# python -u clair_benchmark.py --sim_id=${sim_id} --seed=100 --model_name=RMSN > models/${sim_id}-RMSN.txt &
#done
#
#
#for sim_id in sync1
#do
# python -u clair_benchmark.py --sim_id=${sim_id} --seed=100 --model_name=CRN > models/${sim_id}-CRN-test.txt
#done
#
#for sim_id in sync1
#do
# python -u clair_benchmark.py --sim_id=${sim_id} --seed=100 --model_name=RMSN > models/${sim_id}-RMSN-test.txt
#done

#
#cat models/sync1_MAE.txt

# table 7
#
#cat models/sync1-sc-sum.txt
#cat models/sync1-prognostic_linear.txt
#cat models/sync1-prognostic_none.txt
#cat models/sync1-prognostic_recon.txt



