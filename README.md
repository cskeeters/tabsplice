`tabsplice` is a script to launch vim in diff mode to assist in resolving conflicts from the internal merging of `hg` or `git`.

It's similar to [splice][splice], but it uses `vim`'s builtin tabs to provide multiple views.

`tabsplice` is a modification of [diffconflicts][diffconflicts] by whiteinge that supports mercurial.

[diffconflicts]: https://github.com/whiteinge/dotfiles/blob/master/bin/diffconflicts
[splice]: https://github.com/sjl/splice.vim/

# Context and the tabsplice solution

Premises:

* Vim is the editor you want to use when modifying any text including resolving conflicts.
* *Vim is not a merge tool.*  Another tool must be used to merge changes where no conflict results.
* diff mode only looks good when diffing two buffers (in a tab).
* If a 3-way merge algorithm can determine how to automatically merge some changes but results in conflicts for other changes, the developer should only review the conflicts.

Based on these premises, the solution is to let the internal merge of hg/git or the external merge tool take a first pass at merging.  Then bring up vim in diff mode where both buffers being compared have non-conflicting hunks merged, but differ for the conflicting hunks.  If the buffer in the left split shows the file contents if all conflicts were resolved in favor of the LOCAL version of the file, and the buffer in the right split shows the file contents if all conflicts were resolved in favor of the OTHER version of the file, then vim's diff mode will allow us to

* jump to conflicts using <kbd>[</kbd><kbd>c</kbd> / <kbd>]</kbd><kbd>c</kbd>
* move changes (<kbd>d</kbd><kbd>o</kbd> / <kbd>d</kbd><kbd>p</kbd>)from OTHER to LOCAL in order to create a manually merge version

In order to achieve this solution, we need:

1. Something to perform an initial merge and output the result with conflict markers.
2. Something to make a file where all conflicts resolved in favor of the LOCAL version
3. Something to make a file where all conflicts resolved in favor of the OTHER version
4. Something to open up vim and configure split and enable diffmode (and a few other settings as you prefer)
5. Assuming the contents is manually merged in vim, something to write over the file and mark it resolved.

## Initial merge

Both git and mercurial have an internal merge tool.  Mercurial will perform an internal merge and use the result if there are no conflicts no matter what.  If there are conflicts, then what happens depends on `ui.merge`.  If `ui.merge` is setup for a merge tool, then by default, the result of the internal is discarded (like internal:dump) and typically the files specified by `$base`, `$local`, and `$other` are fed into an external merge tool like kdiff3.  If the merge tool needs the result of the internal merge, then `premerge` can be set to `keep` like so.

    [ui]
    merge=tabsplice

    [merge-tools]
    tabsplice.executable = [path/to/]tabsplice
    tabsplice.premerge = keep

Mercurial versions before 1.6 doesn't support `keep` as a possible value of premerge.  In this case we leave that setting off and tabsplit will detect this situation and run the external program `merge` to re-perform the initial merge.

See `hg help merge-tools` for more info.

## Creating Files for Vim

`tabsplice` uses sed to turn the output of the initial merge into to separate files:

ALL_LOCAL
: all conflicts resolved in favor of LOCAL

ALL_OTHER
: all conflicts resolved in favor of OTHER

## Setting up Vim

`tabsplice` creates a temporary vimscript file with commands to setup the tabs/splits and configure options (that can be easily changed).  Then vim is called with `-c "source <tmp.vim>"`

## Saving

The wrapper script assumes that you will edit the buffer in the left window.  If you save this buffer, `tabsplice` will detect a new modification time on the file and copy this file over the main file in the repository.

When mercurial launches an external tool to merge files with conflicts, it assumes that if that tool exits with a zero status then the merge was completed and the file should be marked resolved.  If when vim loads up, you do not want the file to be marked resolved, exit vim with `:cq`.


# Other Tabs

`tabsplit` is also configured to open up two other tabs.  The first tab described above is the most convenient for identifying only the conflicts from an initial 3-way merge.  Whoever, sometimes neither of these buffers are particularly easy to edit given that <kbd>d</kbd> <kbd>o</kbd> replaces the text in the current buffer with the text from the other buffer.  Also, it may be the case that you want to review the sections of code that were automatically resolved in favor of either the LOCAL or OTHER versions.

For this vim is loaded with the main file which has conflict markers in it.

## Local Tab

The 2nd tab has the main file (with conflict markers) and the clean OTHER version.  Since diff mode is enabled, developers can easily jump between sections of the code that were either automatically merged, or have a conflict.  Resolving the conflict in favor of the LOCAL version is trivial with <kbd>d</kbd> <kbd>o</kbd>.

## Other Tab

The 3nd tab has the main file (with conflict markers) and the clean OTHER version.  Since diff mode is enabled, developers can easily jump between sections of the code that were either automatically merged, or have a conflict.  Resolving the conflict in favor of the OTHER version is trivial with <kbd>d</kbd> <kbd>o</kbd>.

NOTE: **The 2nd and 3rd tab have the same buffer in the left tab.  This will be used as the resolved file, provided the buffer in the left window of the 1st tab has not been saved.**


# Configuration

1. Download this script and name it tabsplice
2. Set it to be executable - `chmod 755 tabsplice`
3. Configure DRCS

    Configuration for mercurial in ~/.hgrc

        [ui]
        merge=tabsplice

        [merge-tools]
        tabsplice.executable = [path/to/]tabsplice
        tabsplice.premerge = keep
        tabsplice.args = $base $local $other $output

    NOTE: Older versions of mercurial require a full path to tabsplice.
            Newer versions just require the script to be located somewhere in your
            PATH.

    NOTE: If your version of mercurial doesn't support premerge=keep (hg before 1.6),
            you can omit that line and `merge` will be used to generate $OUTPUT
            with conflict markers.

    Configuration for git

        git config --global merge.tool tabsplice
        git config --global mergetool.tabsplice.cmd 'tabsplice $BASE $LOCAL $REMOTE $MERGED'
        git config --global mergetool.tabsplice.trustExitCode true
        git config --global mergetool.keepBackup false

4. If you would like to use gvim instead of vim, make sure you have exported
   VISUAL or EDITOR


# Extra Configuration

This script is configured as I would like it.  If you like folds, then remove the line:

    -c "tabdo windo set nofoldenable foldcolumn=0" \

If you would like to customize which views you see, then you can modify

    LEFT
    RIGHT
    T2_LEFT
    T2_RIGHT
    T3_LEFT
    T3_RIGHT


# Useful Vim Commands

<kbd>]</kbd><kbd>c</kbd>
: Move cursor to the next difference block

<kbd>[</kbd><kbd>c</kbd>
: Move cursor to the previous difference block

<kbd>Ctrl</kbd>+<kbd>w</kbd> <kbd>w</kbd>
: Move cursor to the next window

<kbd>g</kbd><kbd>t</kbd>
: Move cursor to the next tab

<kbd>d</kbd><kbd>o</kbd>
: diff obtain

<kbd>d</kbd><kbd>p</kbd>
: diff put

`:cq`
: Quit with non-zero exit status indicating to the script (and DRCS) that the file should be marked unresolved.

`:wqa`
: Write all changed buffers and exit Vim.

`:qa`
: Write all changed buffers and exit Vim.

`:tabonly`
: Close all other tabs

`:tabclose`
: Close this tab

`:tabdo wincmd =`
: Make all windows in all tabs equally wide



# Useful Vim Mappings

```vim
nnoremap ]t :tabnext<cr>
nnoremap [t :tabprevious<cr>
nnoremap ]w :wincmd l<cr>
nnoremap [w :wincmd h<cr>
```
