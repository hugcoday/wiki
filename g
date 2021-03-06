<?php // -*-php-*- $Id: g 7679 2010-09-09 13:25:20Z vargenau $

/*
 * Copyright (C) 2008-2010 Alcatel-Lucent
 *
 * This file is part of PhpWiki.
 *
 * PhpWiki is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * PhpWiki is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with PhpWiki; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

/*
 * Standard Alcatel-Lucent disclaimer for contributing to open source
 *
 * "The Configuration File ("Contribution") has not been tested and/or
 * validated for release as or in products, combinations with products or
 * other commercial use. Any use of the Contribution is entirely made at
 * the user's own responsibility and the user can not rely on any features,
 * functionalities or performances Alcatel-Lucent has attributed to the
 * Contribution.
 *
 * THE CONTRIBUTION BY ALCATEL-LUCENT IS PROVIDED AS IS, WITHOUT WARRANTY
 * OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
 * WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, COMPLIANCE,
 * NON-INTERFERENCE AND/OR INTERWORKING WITH THE SOFTWARE TO WHICH THE
 * CONTRIBUTION HAS BEEN MADE, TITLE AND NON-INFRINGEMENT. IN NO EVENT SHALL
 * ALCATEL-LUCENT BE LIABLE FOR ANY DAMAGES OR OTHER LIABLITY, WHETHER IN
 * CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * CONTRIBUTION OR THE USE OR OTHER DEALINGS IN THE CONTRIBUTION, WHETHER
 * TOGETHER WITH THE SOFTWARE TO WHICH THE CONTRIBUTION RELATES OR ON A STAND
 * ALONE BASIS."
 */

ini_set("memory_limit", "64M");

// Disable compression, seems needed to get all the messages.
$no_gz_buffer=true;

require_once('../../env.inc.php');
require_once $gfcommon.'include/pre.php';
require_once $gfplugins.'wiki/common/wikiconfig.class.php';

if (!$group_id || !$project) {
     exit_no_group();
} else if (!($project->usesPlugin("wiki"))) {
    exit_error("Wiki plugin not activated in project", $project->getPublicName());
} else {

    $group_name = $project->getUnixName();
    $group_public_name = $project->getPublicName();
    $is_external = $project->getIsExternal();

    $wc = new WikiConfig($group_id);

    define('VIRTUAL_PATH', '/wiki/g/'.$group_name);
    define('PAGE_PREFIX', '_g'.$group_id.'_');

    define('THEME', 'fusionforge');

    // For FusionForge, we create some specific pages, located in the theme
    // except for project "help"
    if ($group_name == "help") {
        define('WIKI_PGSRC', 'pgsrc');
    } else {
        define('WIKI_PGSRC', 'themes/fusionforge/pgsrc');
    }

    define('FUSIONFORGE', true);

    define('PATH_INFO_PREFIX', '/'.$group_name . '/');
    define('USE_PATH_INFO', true);

    define('WIKI_NAME', $group_name);

    define('DISABLE_MARKUP_WIKIWORD', $wc->getWikiConfig('DISABLE_MARKUP_WIKIWORD'));

    define('NUM_SPAM_LINKS', 20 * ($wc->getWikiConfig('NUM_SPAM_LINKS')));

    define('ENABLE_RATEIT', $wc->getWikiConfig('ENABLE_RATEIT'));

    define('UPLOAD_FILE_PATH', '/opt/groups/'.WIKI_NAME.'/www/uploads/');
    // define('UPLOAD_DATA_PATH', SERVER_URL . '/www/'.WIKI_NAME.'/uploads/');
    define('UPLOAD_DATA_PATH', '/www/'.WIKI_NAME.'/uploads/');

    // Do not use a directory per user but only one (per project)
    define('UPLOAD_USERDIR', false);

    // Use black list of extensions instead of white list
    define('DISABLE_UPLOAD_ONLY_ALLOWED_EXTENSIONS', true);

    // Get the maximum upload filesize from PHP config
    define('MAX_UPLOAD_SIZE', octets(ini_get('upload_max_filesize')));

    // Disable access log (already in Apache & FusionForge).
    define('ACCESS_LOG_SQL', 0);

    define('DEBUG', ($sys_install_type != 'production'));

    // Postgresql
    define('DATABASE_TYPE', 'SQL');
    // Dummy value (to avoid warning in SystemInfo plugin)
    define('DATABASE_DSN', 'pgsql://localhost/user_phpwiki');

    // Disable VACUUM (they are performed every night)
    define('DATABASE_OPTIMISE_FREQUENCY', 0);

    // TBD: the name should be taken from FusionForge
    // define('ADMIN_USER', 'ACOS Forge Administrator');
    define('ADMIN_USER', 'The PhpWiki programming team');
    // Dummy value
    define('ADMIN_PASSWD', 'xxx');

    // Allow ".svg" as extension
    define('INLINE_IMAGES', 'png|jpg|jpeg|gif|svg');

    // Allow <div> and <span> in wiki code
    define('ENABLE_MARKUP_DIVSPAN', true);

    // Disable ENABLE_ACDROPDOWN, it creates a <style> in the <body> (illegal)
    define('ENABLE_ACDROPDOWN', false);
    define('ENABLE_AJAX', false);

    define('TOOLBAR_PAGELINK_PULLDOWN', false);
    define('TOOLBAR_TEMPLATE_PULLDOWN', false);
    define('TOOLBAR_IMAGE_PULLDOWN', true);

    // Enable external pages
    define('ENABLE_EXTERNAL_PAGES', $is_external);

    // Let all revisions be stored. Default since 1.3.11
    define('MAJOR_MIN_KEEP', 2147483647);
    define('MINOR_MIN_KEEP', 2147483647);
    define('MAJOR_MAX_AGE', 2147483647);
    define('MAJOR_KEEP', 2147483647);
    define('MINOR_MAX_AGE', 2147483647);
    define('MINOR_KEEP', 2147483647);
    define('AUTHOR_MAX_AGE', 2147483647);
    define('AUTHOR_KEEP', 2147483647);
    define('AUTHOR_MIN_AGE', 2147483647);
    define('AUTHOR_MAX_KEEP', 2147483647);

    //
    // Define access rights for the wiki.
    //

    // Do not allow anon users to edit pages
    define('ALLOW_ANON_EDIT', false);

    // Do not allow fake user
    define('ALLOW_BOGO_LOGIN', false);

    // A dedicated auth has been created to get auth from FusionForge
    $USER_AUTH_ORDER = array("FusionForge");
    define('USER_AUTH_ORDER', 'FusionForge');
    define('USER_AUTH_POLICY', 'strict');

    define('EXTERNAL_LINK_TARGET', '_top');

    // Override the default configuration for CONSTANTS before index.php
    $LANG='en'; $LC_ALL='en_US';

    // We use a local interwiki map file
    define('INTERWIKI_MAP_FILE', 'themes/fusionforge/interwiki.map');

    define('DEFAULT_WIKI_PAGES', "");

    define('DBAUTH_AUTH_CHECK', "SELECT IF(passwd='\$password',1,0) as ok FROM plugin_wiki_pref WHERE userid='\$userid'");
    define('DBAUTH_AUTH_USER_EXISTS', "SELECT userid FROM plugin_wiki_pref WHERE userid='\$userid'");
    define('DBAUTH_AUTH_CREATE', "INSERT INTO plugin_wiki_pref (passwd,userid) VALUES ('\$password','\$userid')");
    define('DBAUTH_PREF_SELECT', "SELECT prefs FROM plugin_wiki_pref WHERE userid='\$userid'");
    define('DBAUTH_PREF_UPDATE', "UPDATE plugin_wiki_pref SET prefs='\$pref_blob' WHERE userid='\$userid'");
    define('DBAUTH_PREF_INSERT', "INSERT INTO plugin_wiki_pref (prefs,userid) VALUES ('\$pref_blob','\$userid')");
    define('DBAUTH_IS_MEMBER', "SELECT userid FROM plugin_wiki_pref WHERE userid='\$userid' AND groupname='\$groupname'");
    define('DBAUTH_GROUP_MEMBERS', "SELECT userid FROM plugin_wiki_pref WHERE groupname='\$groupname'");
    define('DBAUTH_USER_GROUPS', "SELECT groupname FROM plugin_wiki_pref WHERE userid='\$userid'");

    define('USE_DB_SESSION', true);

    define('USE_BYTEA', true);

    define('ENABLE_REVERSE_DNS', false);

    // Perhaps propose Web DAV location ?
    define('DEFAULT_DUMP_DIR', "");
    define('HTML_DUMP_DIR', "");

    define('COMPRESS_OUTPUT', false);

    define('CACHE_CONTROL', "NO_CACHE");

    define('DEFAULT_LANGUAGE', "en");

    define('DISABLE_GETIMAGESIZE', true);

    // If the user is logged in, let the Wiki know
    if (session_loggedin()){
        // let php do it's session stuff too!
        //ini_set('session.save_handler', 'files');
        // session_start();
        $user = session_get_user();

        if ($user && is_object($user) && !$user->isError() && $user->isActive()) {
            $user_name = $user->getRealName();
            $_SESSION['user_id'] = $user_name;
            $_SERVER['PHP_AUTH_USER'] = $user_name;
            $HTTP_SERVER_VARS['PHP_AUTH_USER'] = $user_name;
        }
    } else {
        // clear out the globals, just in case...
    }

    // Load the default configuration.
    require_once(dirname(__FILE__).'/lib/prepend.php');
    require_once(dirname(__FILE__).'/lib/IniConfig.php');
    IniConfig(dirname(__FILE__)."/config/config-default.ini");

    // Override the default configuration for VARIABLES after index.php:
    // E.g. Use another DB:
    $DBParams['dbtype'] = 'SQL';
    $DBParams['dsn']    = 'ffpgsql://' . $sys_dbuser . ':' .
        $sys_dbpasswd . '@' . $sys_dbhost .'/' . $sys_dbname;

    $DBParams['prefix'] = "plugin_wiki_";

    // Start the wiki
    include dirname(__FILE__).'/lib/main.php';
}

/**
 * Return a number of octets from a string like "300M"
 */
function octets($val) {
    $val = trim($val);
    $last = strtolower($val[strlen($val)-1]);
    switch($last) {
        // The 'G' modifier is available since PHP 5.1.0
        case 'g':
            $val *= 1024;
        case 'm':
            $val *= 1024;
        case 'k':
            $val *= 1024;
    }
    return $val;
}
?>
