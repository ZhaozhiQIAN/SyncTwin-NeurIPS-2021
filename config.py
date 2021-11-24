import torch

D_TYPE = torch.float32
if torch.cuda.device_count() == 2:
    DEVICE = torch.device("cuda:" + str(1) if torch.cuda.is_available() else "cpu")
else:
    DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")
