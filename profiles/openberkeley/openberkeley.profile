<?php

/**
 * inherit from Panopoly
 */
require_once ('profiles/panopoly/panopoly.profile');

/**
 * Implements hook_install_tasks()
 */
function openberkeley_install_tasks(&$install_state) {
  $ucb_apps_tasks = array();
  $tasks = panopoly_install_tasks($install_state);
  
  // Setup the UC Berkeley Apps install task
  $ucberkeley_server = array(
    'machine name' => 'ucberkeley',
    'default apps' => array(
      'ucb_cas',  
      'ucb_envconf',
      'ucb_smtp',
  ),
  );
  $ucb_apps_tasks = apps_profile_install_tasks($install_state, $ucberkeley_server);
  $ucb_apps_tasks = array_merge($ucb_apps_tasks, array('apps_profile_apps_select_form_ucberkeley' => array('display_name' => t('Install apps for UC Berkeley'))));
  $tasks = array_insert_before($tasks, 'panopoly_theme_form', $ucb_apps_tasks);
  $ucb_smtp_task['openberkely_smtp_configure_form'] = array(
    'display_name' => t('Site email settings'),
    'type' => 'form',    
  );
  $tasks = array_insert_before($tasks, 'panopoly_final_setup', $ucb_smtp_task);

  // Skip "verify apps support" task if obviously not needed
  // is_writeable should really be tested in apps_profile_install_tasks()
  if (is_writable('sites/all/modules')) {
    unset($tasks['apps_install_verify']);
  }

  
  /*
   Tasks:
   apps_install_verify
   apps_profile_apps_select_form_panopoly
   apps_profile_download_app_modules_panopoly
   apps_profile_authorize_transfer_panopoly
   apps_profile_install_app_modules_panopoly
   apps_profile_enable_app_modules_panopoly
   apps_profile_apps_select_form_ucberkeley
   apps_profile_download_app_modules_ucberkeley
   apps_profile_authorize_transfer_ucberkeley
   apps_profile_install_app_modules_ucberkeley
   apps_profile_enable_app_modules_ucberkeley
   panopoly_theme_form
   openberkely_smtp_configure_form
   panopoly_final_setup
   */
  return $tasks;
}

function openberkeley_form_apps_profile_apps_select_form_alter(&$form, $form_state) {
  panopoly_form_apps_profile_apps_select_form_alter($form, $form_state);
}

//LEFT OFF 8/29 test the above and then continue wrapping the next functions.

function openberkeley_install_tasks_alter(&$tasks, $install_state) {
  panopoly_install_tasks_alter($tasks, $install_state);
}

function openberkeley_form_install_configure_form_alter(&$form, $form_state) {
  panopoly_form_install_configure_form_alter($form, $form_state);
  //Override some Panopoly defaults
  $form['site_information']['site_name']['#default_value'] = '';
  $form['admin_account']['account']['name']['#default_value'] = 'ucbadmin';
}

function openberkeley_apps_servers_info() {
  $servers = panopoly_apps_servers_info();
  $servers['ucberkeley'] = array(
      'title' => 'UC Berkeley',
      'description' => 'Apps for UC Berkeley',
      'manifest' => 'http://drupal-apps.berkeley.edu/ucberkeley',
  );
  return $servers;
}

function openberkeley_form_apps_profile_apps_select_form_alter(&$form, $form_state) {
  panopoly_form_apps_profile_apps_select_form_alter($form, $form_state);
}

//LEFT OFF 8/23

/**
 * Form to configure smtp
 */
function openberkeley_smtp_configure_form($form, &$form_state) {

  // Set the title
  //drupal_set_title(t('Configure theme settings!'));

  //$theme = variable_get('theme_default');
  ctools_include('smtp.admin', 'smtp', '');
  $form = smtp_admin_settings();
  return $form;
}

/**
 * smtp_test
 */
function openberkeley_smtp_test() {

  // Send the smtp test message
  // If an address was given, send a test e-mail message.
  $test_address = variable_get('smtp_test_address', '');
  if ($test_address != '') {
    // Clear the variable so only one message is sent.
    variable_del('smtp_test_address');
    global $language;
    $params['subject'] = t('SMTP test e-mail from Drupal site');
    $params['body']    = array(t('If you receive this message it means your site is capable of using '. variable_get('smtp_host', '') .' to send e-mail.'));
    drupal_mail('smtp', 'smtp-test', $test_address, $language, $params);
    drupal_set_message(t('A test e-mail has been sent to @email. You may want to !check for any error messages once this installation is finished.', array('@email' => $test_address, '!check' => l(t('check the logs'), 'admin/reports/dblog'))));
  }

}

/**
 * Assign "administrative user" role all permissions
 */
function openberkeley_adminrole() {
  if ($rid = variable_get('user_admin_role')) {
    $permissions = drupal_map_assoc(array_keys(module_invoke_all('permission')));
    $current = user_role_permissions(array($rid => $rid));
    foreach ($current[$rid] as $permission => $status) {
      if (!isset($permissions[$permission])) {
        $permissions[$permission] = FALSE;
      }
    }
    user_role_change_permissions($rid, $permissions);
  }
}


//TODO add this to Libraries?
/*
 *
 * Insert an $ins_array into $array before $array[$key_before]
 */
function array_insert_before($array, $key_before, $ins_array) {

  $keys1 = array_keys($array);
  $vals1 = array_values($array);

  $ins_keys = array_keys($ins_array);
  $ins_vals = array_values($ins_array);

  $insert_before = array_search($key_before, $keys1);

  $keys2 = array_splice($keys1, $insert_before);
  $vals2 = array_splice($vals1, $insert_before);

  $keys1 = array_merge($keys1, $ins_keys);
  $vals1 = array_merge($vals1, $ins_vals);

  $new = array_merge(array_combine($keys1, $vals1), array_combine($keys2, $vals2));

  return $new;
}