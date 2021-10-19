


nohup python -u real_data.py --model_id=m50 --n_hidden=50 --itr_pretrain=10000 --itr=5 --fold=3 > models/real-data-m50.txt &

nohup python -u real_data.py --model_id=m100 --n_hidden=100 --itr_pretrain=10000 --itr=5 --fold=3 > models/real-data-m100.txt &

nohup python -u real_data.py --model_id=m100 --n_hidden=150 --itr_pretrain=15000 --itr=5 --fold=3 > models/real-data-m150.txt &


nohup python -u real_data.py --model_id=m100-v3 --n_hidden=100 --itr_pretrain=15000 --itr=2 --fold=3 --data_version=3 > models/real-data-m100-v2.txt &


nohup python -u real_data_inference.py --model_id=m100-v3 --n_hidden=100 --itr_fine_tune=10000 --batch_size=1500 --data_version=3 > models/real-data-inference-m100.txt &
