<?php

$aliases['dev-_PROJECT_NAME_'] = array(
  'root' => '_DRUPAL_ROOT_',
  'uri' => 'dev-_PROJECT_NAME_.emergyalabs.com',
);

$aliases['ci-_PROJECT_NAME_'] = array(
  'root' => '_DRUPAL_ROOT_',
  'uri' => 'ci-_PROJECT_NAME_.emergyalabs.com',
  'remote-host' => 'ci-_PROJECT_NAME_.emergyalabs.com',
  'remote-user' => 'developer',
  'ssh-options' => '-i ~/.ssh/_PROJECT_NAME_.pem -p 22122'
);

$aliases['qa-_PROJECT_NAME_'] = array(
  'root' => '_DRUPAL_ROOT_',
  'uri' => 'qa-_PROJECT_NAME_.emergyalabs.com',
  'remote-host' => 'qa-_PROJECT_NAME_.emergyalabs.com',
  'remote-user' => 'developer',
  'ssh-options' => '-i ~/.ssh/_PROJECT_NAME_.pem -p 22122'
);

$aliases['stg-_PROJECT_NAME_'] = array(
  'root' => '_DRUPAL_ROOT_',
  'uri' => 'stg-_PROJECT_NAME_.emergyalabs.com',
  'remote-host' => 'stg-_PROJECT_NAME_.emergyalabs.com',
  'remote-user' => 'developer',
  'ssh-options' => '-i ~/.ssh/_PROJECT_NAME_.pem -p 22122'
);

$aliases['pre-_PROJECT_NAME_'] = array(
  'root' => '_DRUPAL_ROOT_',
  'uri' => 'pre-_PROJECT_NAME_.emergyalabs.com',
  'remote-host' => 'pre-_PROJECT_NAME_.emergyalabs.com',
  'remote-user' => 'ubuntu',
  'ssh-options' => '-i ~/.ssh/_PROJECT_NAME_.pem -p 22122'
);

$aliases['pro-_PROJECT_NAME_'] = array(
  'root' => '_DRUPAL_ROOT_',
  'uri' => 'pro-_PROJECT_NAME_.emergyalabs.com',
  'remote-host' => 'pro-_PROJECT_NAME_.emergyalabs.com',
  'remote-user' => 'ubuntu',
  'ssh-options' => '-i ~/.ssh/_PROJECT_NAME_.pem -p 22122'
);
