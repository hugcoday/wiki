<?php // -*-php-*-
rcs_id('$Id: WikiAdminMassRevert.php,v 1.30 2004/11/23 15:17:19 rurban Exp $');
/*
 Copyright 2006 $ThePhpWikiProgrammingTeam

 This file is (not yet) part of PhpWiki.

 PhpWiki is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.

 PhpWiki is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with PhpWiki; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

/**
 * Usage:   <?plugin WikiAdminMassRevert ?>
 * Author:  Reini Urban <rurban@x-ray.at>
 *
 * Present "smart" list of pages from a recent massedit by a 
 * single user, selectable by username or IP.
 * Special diff column for a short preview of the last edit.
 * Revert to previous version by selecting (all) on checkbox.
 *
 * Only avaliable for Admins.
 */
require_once('lib/PageList.php');
require_once('lib/plugin/WikiAdminSelect.php');

class WikiPlugin_WikiAdminMassRevert
extends WikiPlugin_WikiAdminSelect
{
    function getName() {
        return _("WikiAdminMassRevert");
    }

    function getDescription() {
        return _("Revert a selection of pages from a recent massedit from a single spammer.");
    }

    function getVersion() {
        return preg_replace("/[Revision: $]/", '',
                            "\$Revision: 1.30 $");
    }

    function getDefaultArguments() {
        return array_merge
            (
             PageList::supportedArgs(),
             array(
                   's' 	=> false,
                   /*
                    * Show only pages which have been changed this
                    * long (in days).
                    */
                   'min_age' => 0,
                   /*
                    * Automatically check the checkboxes for files
                    * which have been changed this long (in days).
                    */
                   'max_age' => 31,
                   'author'  => false,
                   /* Columns to include in listing */
                   'info'     => 'author,mtime,diff,version',
                   ));
    }

    function collectPages(&$list, &$dbi, $sortby, $limit=0) {
        extract($this->_args);

        $now = time();
        // Smart RecentChanges by a single user
        $allPages = $dbi->getAllPages('include_empty',$sortby,$limit);
        while ($pagehandle = $allPages->next()) {
            $pagename = $pagehandle->getName();
            $current = $pagehandle->getCurrentRevision();
            if ($current->getVersion() < 1)
                continue;       // No versions in database

            $empty = $current->hasDefaultContents();
            if ($empty) {
                $age = ($now - $current->get('mtime')) / (24 * 3600.0);
                $checked = $age >= $max_age;
            }
            else {
                $age = 0;
                $checked = false;
            }

            if ($age >= $min_age) {
                if (empty($list[$pagename]))
                    $list[$pagename] = $checked;
            }
        }
        return $list;
    }

    function revertPages(&$request, $pages) {
        $ul = HTML::ul();
        $dbi = $request->getDbh(); $count = 0;
        foreach ($pages as $name) {
            $name = str_replace(array('%5B','%5D'),array('[',']'),$name);
            if (mayAccessPage('remove',$name)) {
                $version = $dbi->revertPage($name);
                $ul->pushContent
                    (HTML::li(fmt("Reverted page '%s' to version '%s'.", $name, $version)));
                $count++;
            } else {
            	$ul->pushContent
                    (HTML::li(fmt("Didn't revert page '%s'. Access denied.", $name)));
            }
        }
        if ($count) $dbi->touch();
        return HTML($ul,
                    HTML::p(fmt("%d pages have been reverted.",$count)));
    }
    
    function run($dbi, $argstr, &$request, $basepage) {
        if ($request->getArg('action') != 'browse')
            if ($request->getArg('action') != _("PhpWikiAdministration/MassRevert"))
                return $this->disabled("(action != 'browse')");
        
        $args = $this->getArgs($argstr, $request);
        if (!is_numeric($args['min_age']))
            $args['min_age'] = -1;
        $this->_args =& $args;
        /*if (!empty($args['exclude']))
            $exclude = explodePageList($args['exclude']);
        else
        $exclude = false;*/
        $this->preSelectS($args, $request);

        $p = $request->getArg('p');
        if (!$p) $p = $this->_list;
        $post_args = $request->getArg('admin_revert');

        $next_action = 'select';
        $pages = array();
        if ($p && $request->isPost() &&
            !empty($post_args['revert']) && empty($post_args['cancel'])) {

            // check individual PagePermissions
            if (!ENABLE_PAGEPERM and !$request->_user->isAdmin()) {
                $request->_notAuthorized(WIKIAUTH_ADMIN);
                $this->disabled("! user->isAdmin");
            }
            if ($post_args['action'] == 'verify') {
                // Real delete.
                return $this->revertPages($request, array_keys($p));
            }

            if ($post_args['action'] == 'select') {
                $next_action = 'verify';
                foreach ($p as $name => $c) {
                    $name = str_replace(array('%5B','%5D'),array('[',']'),$name);
                    $pages[$name] = $c;
                }
            }
        } elseif ($p && is_array($p) && !$request->isPost()) { // from WikiAdminSelect
            $next_action = 'verify';
            foreach ($p as $name => $c) {
                $name = str_replace(array('%5B','%5D'),array('[',']'),$name);
                $pages[$name] = $c;
            }
            $request->setArg('p',false);
        }
        if ($next_action == 'select') {
            // List all pages to select from.
            $pages = $this->collectPages($pages, $dbi, 
                                         $args['sortby'], 
                                         $args['limit'], 
                                         $args['exclude']);
        }
        $pagelist = new PageList_Selectable
            ($args['info'], $args['exclude'], 
             array('types' => 
                   array('revert'
                         => new _PageList_Column_revert('revert', _("Revert")),
                         'diff'
                         => new _PageList_Column_diff('diff', _("Changes"))
                         )));
        $pagelist->addPageList($pages);

        $header = HTML::p();
        if ($next_action == 'verify') {
            $button_label = _("Yes");
            $header->pushContent(HTML::strong(
                _("Are you sure you want to overwrite the selected files with the previous version?")));
        }
        else {
            $button_label = _("Revert selected pages");
            $header->pushContent(_("Permanently remove the selected files:"),HTML::br());
            if ($args['min_age'] > 0) {
                $header->pushContent(
                    fmt("Also pages which have been deleted at least %s days.",
                        $args['min_age']));
            }
            else {
                $header->pushContent(_("List all pages."));
            }
            
            if ($args['max_age'] > 0) {
                $header->pushContent(
                    " ",
                    fmt("(Pages which have been deleted at least %s days are already checked.)",
                        $args['max_age']));
            }
        }


        $buttons = HTML::p(Button('submit:admin_revert[revert]', $button_label, 'wikiadmin'),
                           Button('submit:admin_revert[cancel]', _("Cancel"), 'button'));

        // TODO: quick select by regex javascript?
        return HTML::form(array('action' => $request->getPostURL(),
                                'method' => 'post'),
                          $header,
                          $pagelist->getContent(),
                          HiddenInputs($request->getArgs(),
                                        false,
                                        array('admin_revert')),
                          HiddenInputs(array('admin_revert[action]' => $next_action,
                                             'require_authority_for_post' => WIKIAUTH_ADMIN)),
                          $buttons);
    }
}

class _PageList_Column_revert extends _PageList_Column {
    function _getValue ($page_handle, &$revision_handle) {
        return Button(array('action' => 'revert'), _("Revert"),
                      $page_handle->getName());
    }
};

/*
 * Shortened preview of the diff to the previous pagerevision.
 */
class _PageList_Column_diff extends _PageList_Column {
    function _getValue ($page_handle, &$revision_handle) {
        return '';
    }
};

// $Log: WikiAdminMassRevert.php,v $

// Local Variables:
// mode: php
// tab-width: 8
// c-basic-offset: 4
// c-hanging-comment-ender-p: nil
// indent-tabs-mode: nil
// End:
?>
