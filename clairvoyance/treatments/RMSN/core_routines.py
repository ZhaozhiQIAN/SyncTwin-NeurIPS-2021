"""

CODE ADAPTED FROM: https://github.com/sjblim/rmsn_nips_2018

Treatment Effects with RNNs:

Common routines to use across all training scripts

"""

import treatments.RMSN.configs

from treatments.RMSN.libs.model_rnn import RnnModel
import treatments.RMSN.libs.net_helpers as helpers

import tensorflow as tf
import pandas as pd
import numpy as np
import logging
import os
import pickle
from sklearn.model_selection import ShuffleSplit, KFold

ROOT_FOLDER = treatments.RMSN.configs.ROOT_FOLDER
MODEL_ROOT = treatments.RMSN.configs.MODEL_ROOT

logger = logging.getLogger()
logger.disabled = True
# --------------------------------------------------------------------------
# Training routine
# --------------------------------------------------------------------------
def train(net_name,
          expt_name,
          training_dataset, validation_dataset,
          dropout_rate,
          memory_multiplier,
          num_epochs,
          minibatch_size,
          learning_rate,
          max_norm,
          use_truncated_bptt,
          num_features,
          num_outputs,
          model_folder,
          hidden_activation,
          output_activation,
          tf_config,
          additonal_info="",
          b_use_state_initialisation=False,
          b_use_seq2seq_feedback=False,
          b_use_seq2seq_training_mode=False,
          adapter_multiplier=0,
          b_use_memory_adapter=False):
  """
  Common training routine to all RNN models - seq2seq + standard
  """

  min_epochs = 1

  tf.reset_default_graph()
  with tf.Graph().as_default(), tf.Session(config=tf_config) as sess:

    tf_data_train = convert_to_tf_dataset(training_dataset)
    tf_data_valid = convert_to_tf_dataset(validation_dataset)

    # Setup default hidden layer size
    hidden_layer_size = int(memory_multiplier * num_features)

    if b_use_state_initialisation:

      full_state_size = int(training_dataset['initial_states'].shape[-1])

      adapter_size = adapter_multiplier * full_state_size

    else:
      adapter_size = 0

    # Training simulation
    model_parameters = {'net_name': net_name,
                        'experiment_name': expt_name,
                        'training_dataset': tf_data_train,
                        'validation_dataset': tf_data_valid,
                        'test_dataset': None,
                        'dropout_rate': dropout_rate,
                        'input_size': num_features,
                        'output_size': num_outputs,
                        'hidden_layer_size': hidden_layer_size,
                        'num_epochs': num_epochs,
                        'minibatch_size': minibatch_size,
                        'learning_rate': learning_rate,
                        'max_norm': max_norm,
                        'model_folder': model_folder,
                        'hidden_activation': hidden_activation,
                        'output_activation': output_activation,
                        'backprop_length': 60,  # backprop over 60 timesteps for truncated backpropagation through time
                        'softmax_size': 0,  # not used in this paper, but allows for categorical actions
                        'performance_metric': 'xentropy' if output_activation == 'sigmoid' else 'mse',
                        'use_seq2seq_feedback': b_use_seq2seq_feedback,
                        'use_seq2seq_training_mode': b_use_seq2seq_training_mode,
                        'use_memory_adapter': b_use_memory_adapter,
                        'memory_adapter_size': adapter_size}

    # Get the right model
    model = RnnModel(model_parameters)
    serialisation_name = model.serialisation_name

    if helpers.hyperparameter_result_exists(model_folder, net_name, serialisation_name):
      logging.warning("Combination found: skipping {}".format(serialisation_name))
      return helpers.load_hyperparameter_results(model_folder, net_name)

    training_handles = model.get_training_graph(use_truncated_bptt=use_truncated_bptt,
                                                b_use_state_initialisation=b_use_state_initialisation)
    validation_handles = model.get_prediction_graph(use_validation_set=True, with_dropout=False,
                                                    b_use_state_initialisation=b_use_state_initialisation)

    # Start optimising
    num_minibatches = int(np.ceil(training_dataset['scaled_inputs'].shape[0] / model_parameters['minibatch_size']))

    i = 1
    epoch_count = 1
    step_count = 1
    min_loss = np.inf
    with sess.as_default():

      sess.run(tf.global_variables_initializer())

      optimisation_summary = pd.Series([])

      while True:
        try:
          loss, _ = sess.run([training_handles['loss'],
                              training_handles['optimiser']])

          # Flog output
          logging.info("Epoch {} | iteration = {} of {}, loss = {} | net = {} | info = {}".format(
            epoch_count,
            step_count,
            num_minibatches,
            loss,
            model.net_name,
            additonal_info))

          if step_count == num_minibatches:

            # Reinit dataset
            sess.run(validation_handles['initializer'])

            means = []
            UBs = []
            LBs = []
            while True:
              try:
                mean, upper_bound, lower_bound = sess.run([validation_handles['mean'],
                                                           validation_handles['upper_bound'],
                                                           validation_handles['lower_bound']])

                means.append(mean)
                UBs.append(upper_bound)
                LBs.append(lower_bound)
              except tf.errors.OutOfRangeError:
                break

            means = np.concatenate(means, axis=0)

            active_entries = validation_dataset['active_entries']
            output = validation_dataset['scaled_outputs']

            if model_parameters['performance_metric'] == "mse":
              validation_loss = np.sum((means - output) ** 2 * active_entries) / np.sum(active_entries)

            elif model_parameters['performance_metric'] == "xentropy":
              _, _, features_size = output.shape
              partition_idx = features_size
              # Do binary first
              validation_loss = np.sum((output[:, :, :partition_idx] * -np.log(means[:, :, :partition_idx] + 1e-5)
                                        + (1 - output[:, :, :partition_idx]) * -np.log(
                    1 - means[:, :, :partition_idx] + 1e-5))
                                       * active_entries[:, :, :partition_idx]) \
                                / (np.sum(active_entries[:, :, :partition_idx]))

            optimisation_summary[epoch_count] = validation_loss

            # Compute validation loss
            logging.info("Epoch {} Summary| Validation loss = {} | net = {} | info = {}".format(
              epoch_count,
              validation_loss,
              model.net_name,
              additonal_info))

            if np.isnan(validation_loss):
              logging.warning("NAN Loss found, terminating routine")
              break

            # Save model and loss trajectories
            if validation_loss < min_loss and epoch_count > min_epochs:
              cp_name = serialisation_name + "_optimal"
              helpers.save_network(sess, model_folder, cp_name, optimisation_summary)
              min_loss = validation_loss

            # Update
            epoch_count += 1
            step_count = 0

          step_count += 1
          i += 1

        except tf.errors.OutOfRangeError:
          break

      # Save final
      cp_name = serialisation_name + "_final"
      helpers.save_network(sess, model_folder, cp_name, optimisation_summary)
      helpers.add_hyperparameter_results(optimisation_summary, model_folder, net_name, serialisation_name)

      hyperparam_df = helpers.load_hyperparameter_results(model_folder, net_name)

      logging.info("Terminated at iteration {}".format(i))
      sess.close()

  return hyperparam_df


# --------------------------------------------------------------------------
# Test routine
# --------------------------------------------------------------------------
def test(test_dataset,
         tf_config,
         net_name,
         expt_name,
         dropout_rate,
         num_features,
         num_outputs,
         memory_multiplier,
         num_epochs,
         minibatch_size,
         learning_rate,
         max_norm,
         hidden_activation,
         output_activation,
         model_folder,
         b_use_state_initialisation=False,
         b_dump_all_states=False,
         b_mse_by_time=False,
         b_use_seq2seq_feedback=False,
         b_use_seq2seq_training_mode=False,
         adapter_multiplier=0,
         b_use_memory_adapter=False
         ):
  """
  Common test routine to all RNN models - seq2seq + standard
  """

  # Start with graph
  tf.reset_default_graph()

  with tf.Session(config=tf_config) as sess:
    tf_data_test = convert_to_tf_dataset(test_dataset)

    # For decoder training with external state inputs
    if b_use_state_initialisation:

      full_state_size = int(test_dataset['initial_states'].shape[-1])

      adapter_size = adapter_multiplier * full_state_size

    else:
      adapter_size = 0

    # Training simulation
    model_parameters = {'net_name': net_name,
                        'experiment_name': expt_name,
                        'training_dataset': tf_data_test,
                        'validation_dataset': tf_data_test,
                        'test_dataset': tf_data_test,
                        'dropout_rate': dropout_rate,
                        'input_size': num_features,
                        'output_size': num_outputs,
                        'hidden_layer_size': int(memory_multiplier * num_features),
                        'num_epochs': num_epochs,
                        'minibatch_size': minibatch_size,
                        'learning_rate': learning_rate,
                        'max_norm': max_norm,
                        'model_folder': model_folder,
                        'hidden_activation': hidden_activation,
                        'output_activation': output_activation,
                        'backprop_length': 60,
                        # Length for truncated backpropagation over time, matches max time steps here.
                        'softmax_size': 0,  # not used in this paper, but allows for categorical actions
                        'performance_metric': 'xentropy' if output_activation == 'sigmoid' else 'mse',
                        'use_seq2seq_feedback': b_use_seq2seq_feedback,
                        'use_seq2seq_training_mode': b_use_seq2seq_training_mode,
                        'use_memory_adapter': b_use_memory_adapter,
                        'memory_adapter_size': adapter_size}

    # Start optimising
    with sess.as_default():

      sess.run(tf.global_variables_initializer())

      # Get the right model
      model = RnnModel(model_parameters)
      handles = model.get_prediction_graph(use_validation_set=False if 'treatment_rnn' not in net_name else None,
                                           with_dropout=False,
                                           b_use_state_initialisation=b_use_state_initialisation,
                                           b_dump_all_states=b_dump_all_states)

      # Load checkpoint
      serialisation_name = model.serialisation_name
      cp_name = serialisation_name + "_optimal"
      _ = helpers.load_network(sess, model_folder, cp_name)

      # Init
      sess.run(handles['initializer'])

      # Get all the data out in chunks
      means = []
      UBs = []
      LBs = []
      states = []
      while True:
        try:
          mean, upper_bound, lower_bound, ave_states \
            = sess.run([handles['mean'],
                        handles['upper_bound'],
                        handles['lower_bound'],
                        handles['ave_states']])

          means.append(mean)
          UBs.append(upper_bound)
          LBs.append(lower_bound)
          states.append(ave_states)
        except tf.errors.OutOfRangeError:
          break

      means = np.concatenate(means, axis=0)

      states = np.concatenate(states, axis=0)

      active_entries = test_dataset['active_entries'] \
        if net_name != 'treatment_rnn' else test_dataset['active_entries']
      output = test_dataset['scaled_outputs'] \
        if net_name != 'treatment_rnn' else test_dataset['scaled_outputs']

      # prediction_map[net_name] = means
      # output_map[net_name] = output

      if b_mse_by_time:
        mse = np.sum((means - output) ** 2 * active_entries, axis=0) / np.sum(active_entries, axis=0)
      else:
        mse = np.sum((means - output) ** 2 * active_entries) / np.sum(active_entries)

      # results[net_name] = mse
      # print(net_name, mse)
      sess.close()

    return means, output, mse, states


# --------------------------------------------------------------------------
# Data processing functions
# --------------------------------------------------------------------------

def convert_to_tf_dataset(dataset_map):
  key_map = {'inputs': dataset_map['scaled_inputs'],
             'outputs': dataset_map['scaled_outputs'],
             'active_entries': dataset_map['active_entries'],
             'sequence_lengths': dataset_map['sequence_lengths']}

  if 'propensity_weights' in dataset_map:
    key_map['propensity_weights'] = dataset_map['propensity_weights']

  if 'initial_states' in dataset_map:
    key_map['initial_states'] = dataset_map['initial_states']

  tf_dataset = tf.data.Dataset.from_tensor_slices(key_map)

  return tf_dataset


def get_processed_data(dataset, b_predict_actions, b_use_actions_only):
  previous_treatments = dataset['previous_treatments']
  current_treatments = dataset['current_treatments']
  covariates = dataset['current_covariates']
  dataset_outputs = dataset['outputs']
  sequence_lengths = dataset['sequence_lengths']
  active_entries = dataset['active_entries']

  # Parcelling INPUTS
  if b_predict_actions:
    if b_use_actions_only:
      inputs = previous_treatments
      actions = previous_treatments

    else:
      # Uses current covariate, to remove confounding effects between action and current value
      inputs = np.concatenate([covariates, previous_treatments], axis=2)
      actions = previous_treatments

  else:
    inputs = np.concatenate([covariates, current_treatments], axis=2)
    actions = current_treatments

  # Parcelling OUTPUTS
  if b_predict_actions:
    outputs = current_treatments

  else:
    outputs = dataset_outputs

  return {'scaled_inputs': inputs,
          'scaled_outputs': outputs,
          'actions': actions,
          'sequence_lengths': sequence_lengths,
          'active_entries': active_entries}
