<?php

/**
 * inherit from Panopoly
 */
require_once ('profiles/panopoly/panopoly.profile');

/**
 * Implements hook_install_tasks()
 */
function openberkeley_install_tasks(&$install_state) {

  //$ucb_apps_tasks = array();
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


  $ucb_apps_task = apps_profile_install_tasks($install_state, $ucberkeley_server);
  //WARNING: array_insert_before on these tasks causes craziness
  $tasks = array_insert_before($tasks, 'panopoly_theme_form', $ucb_apps_task);
  /*
   // old way
   $tasks = $tasks + apps_profile_install_tasks($install_state, $ucberkeley_server);
   */
  $tasks['apps_profile_apps_select_form_ucberkeley']['display_name'] = t('Install apps for UC Berkeley');

  // Add ucb_smtp task
  $ucb_smtp_task['openberkeley_smtp_configure_form'] = array(
    'display_name' => t('Site email settings'),
    'type' => 'form',    
  );
  //improve? array_insert_before so we don't pop it off in the next step
  $tasks = array_insert_before($tasks, 'panopoly_final_setup', $ucb_smtp_task);

  // Replace panopoly_final_setup with openberkeley_final_setup
  $panopoly_final_setup = array_pop($tasks);
  $tasks['openberkeley_final_setup'] = array(
    'run' => '2',
  );

  // Skip "verify apps support" task if obviously not needed
  // is_writeable should really be tested in apps_profile_install_tasks()
  if (is_writable('sites/all/modules')) {
    unset($tasks['apps_install_verify']);
  }


  /*
   Tasks:

   apps_profile_apps_select_form_panopoly	Array [3]
   apps_profile_download_app_modules_panopoly	Array [4]
   apps_profile_authorize_transfer_panopoly	Array [4]
   apps_profile_install_app_modules_panopoly	Array [4]
   apps_profile_enable_app_modules_panopoly	Array [4]
   apps_profile_apps_select_form_ucberkeley	Array [1]
   apps_profile_download_app_modules_ucberkeley	Array [4]
   apps_profile_authorize_transfer_ucberkeley	Array [4]
   apps_profile_install_app_modules_ucberkeley	Array [4]
   apps_profile_enable_app_modules_ucberkeley	Array [4]
   panopoly_theme_form	Array [2]
   openberkely_smtp_configure_form	Array [2]
   panopoly_final_setup	Array [1]

   */
  return $tasks;
}


/**
 * Implements hook_form_FORM_ID_alter()
 */
function openberkeley_form_apps_profile_apps_select_form_alter(&$form, $form_state) {
  //quell messages
  drupal_get_messages();

  //First figure out what form we are on so that we can call the correct manifest
  $keys = array_keys($form['apps_fieldset']['apps']['#options']);
  if (strpos($keys[0], 'ucb_') === FALSE) {
    //we're on the Panopoly apps form
    panopoly_form_apps_profile_apps_select_form_alter($form, $form_state);
  }
  else {
    //we're on the UCB apps form
    // For some things there are no need
    $form['apps_message']['#access'] = FALSE;
    $form['apps_fieldset']['apps']['#title'] = NULL;

    // Improve style of apps selection form
    if (isset($form['apps_fieldset'])) {
      $options = array();
      $manifest = apps_manifest(apps_servers('ucberkeley'));
      foreach ($manifest['apps'] as $name => $app) {
        if ($name != '#theme') {
          $options[$name] = '<strong>' . $app['name'] . '</strong><p><div class="admin-options"><div class="form-item">' . theme('image', array('path' => $app['logo']['path'], 'height' => '32', 'width' => '32')) . '</div>' . $app['description'] . '</div></p>';
        }
      }
      ksort($options);
      $form['apps_fieldset']['apps']['#options'] = $options;
    }

    // Remove the demo content selection option since this is
    // handled through the Panopoly demo module.
    $form['default_content_fieldset']['#access'] = FALSE;

    // Remove the "skip this step" option since why would we want that?
    $form['actions']['skip']['#access'] = FALSE;

  }
}




function openberkeley_install_tasks_alter(&$tasks, $install_state) {
  panopoly_install_tasks_alter($tasks, $install_state);
  $tasks['install_load_profile']['function'] = 'openberkeley_install_load_profile';

}

/**
 * Override install_load_profile to parse base profile for dependencies
 * @param unknown_type $install_state
 */

function openberkeley_install_load_profile(&$install_state) {
  $profile_file = DRUPAL_ROOT . '/profiles/' . $install_state['parameters']['profile'] . '/' . $install_state['parameters']['profile'] . '.profile';
  if (file_exists($profile_file)) {
    include_once $profile_file;
    // Respect the 'base' info file parameter and load the base profile's dependencies
    $active_profile_info = install_profile_info($install_state['parameters']['profile'], $install_state['parameters']['locale']);
    if (array_key_exists('base', $active_profile_info) && (isset($active_profile_info['base']))) {
      $base_profile_info = install_profile_info(strtolower($active_profile_info['base']), $install_state['parameters']['locale']);
      $active_profile_info['dependencies'] = array_unique(array_merge($active_profile_info['dependencies'], $base_profile_info['dependencies']));
    }
    $install_state['profile_info'] = $active_profile_info;
  }
  else {
    throw new Exception(st('Sorry, the profile you have chosen cannot be loaded.'));
  }
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

/* not needed

function openberkeley_theme_form($form, &$form_state) {
return panopoly_theme_form($form, $form_state);
}

function openberkeley_theme_form_submit($form, &$form_state) {
return panopoly_theme_form_submit($form, $form_state);
}

*/

/**
 * Handler callback to do additional setup reqired for the site to be awesome
 */
function openberkeley_final_setup(&$install_state) {
  drupal_get_messages();
  drupal_set_message('Final!', 'status');
  // Allow anonymous and authenticated users to see and search content
  panopoly_final_setup($install_state);
  // make sure the admin role has all permissions.
  openberkeley_adminrole();

}


/**
 * Form to configure smtp
 */
function openberkeley_smtp_configure_form($form, &$form_state) {
  drupal_get_messages(); //shh
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
        $permissions[$permission] = TRUE;
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