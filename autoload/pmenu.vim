" =============================================================================
" Filename:    autoload/pmenu.vim
" Author:      luzhlon
" Date:        2017-10-30
" Description: ...
" =============================================================================

" Echo prompt and get the item {{{
fun! s:prompt() dict
    let stack_names = [self.name]
    let stack_items = [self.items]
    let flag = ''

    while 1
        let items = stack_items[-1]
        call s:echo_prompt(stack_names, items)
        let key = s:strip_alt(getchar())
        if key == g:popup.upkey
            " Leave menu
            if len(stack_names) < 2 | return | endif
            call remove(stack_names, -1)
            call remove(stack_items, -1)
            continue
        endif

        let item = s:find_item(items, key)
        if empty(item) | break | endif
        let [k, n, C] = item                " key, name, command

        if k[len(k)-1] == ':' || k[len(k)-1] == '!'
            let flag = k[len(k)-1]
        endif

        let t = type(C)
        if t == type([])                    " Enter submenu
            call add(stack_names, n)
            call add(stack_items, C)
        else
            return [t == type(function("tr")) ? C(): C, flag]
        endif
    endw
endf
" }}}

" Popup this menu {{{
fun! s:popup(...) dict
    " Store options
    let [lz, ch, ut] = [&lz, &ch, &ut]
    set nolazyredraw
    set ut=100000000

    let ret = self.prompt()

    " Restore options
    let [&lz, &ch, &ut] = [lz, ch, ut]
    echo "\r"

    return ret
endf
" }}}

" Add a menu item
fun! s:add_item(char, description, keys) dict
    call add(self.items, [a:char, a:description, a:keys])
endf

" transform key code to string
fun! s:keycode2str(key)
    if a:key[len(a:key)-1] == ':' || a:key[len(a:key)-1] == '!'
        let a_key = a:key[0:len(a:key)-2]
    else
        let a_key = a:key
    endif
    let keycode = {"\<F1>":'F1',"\<F2>":'F2',"\<F3>":'F3',"\<F4>":'F4',
                \"\<F5>":'F5',"\<F6>":'F6',"\<F7>":'F7',"\<F8>":'F8',
                \"\<F9>":'F9',"\<F10>":'F10',"\<F11>":'F11',"\<F12>":'F12',
                \"\<space>":'SPACE'
                \}
    if get(keycode, a_key, -1) != -1
        return keycode[a_key]
    else
        return strtrans(a_key)
    endif
endf

" Echo prompt {{{
fun! s:echo_prompt(names, items)
    echo ''
    let &cmdheight = len(a:items) + 1
    " Echo the menu names
    echoh Boolean | echon join(a:names, g:popup.arrow) ':'
    " count the maximum length of item's names
    let maxnamelen = 0
    for item in a:items
        let n = strdisplaywidth(item[1])
        let maxnamelen = n > maxnamelen ? n : maxnamelen
    endfo
    let restlen = &columns - 8 - maxnamelen - 4
    if restlen < 0 | let restlen = 0 | endif
    " show the menu's items
    for item in a:items
        echon "\n"
        if type(item) == type("")
            echoh Comment | echon item
            continue
        endif
        let [k, n, C] = item                " key, name, command
        "echoh Normal | echon ''
        echoh Underlined  | echon printf('%5S',s:keycode2str(k))
        echoh Normal | echon '|  '
        echoh Type | echon n
        echon repeat(' ', maxnamelen - strdisplaywidth(n) + 2)
        let t = type(C)
        if t == type({}) || t == type([])   " Submenu
            echoh WarningMsg | echon '>'
        elseif t == type(function("tr"))                " Function
            echoh Include | echon string(C)[:restlen]
        else                                " Command
            echoh Function | echon strtrans(C)[:restlen]
        endif
    endfo
    echoh None
    " redraw
endf
" }}}

" Merge with another menu {{{
fun! s:merge(m) dict
    let self.items += a:m.items
    return self
endf
" }}}

" Find a item {{{
fun! s:find_item(items, key)
    for item in a:items
        if type(item) == type([])
            let l = len(item[0])
            if item[0][l-1] == ':' || item[0][l-1] == '!'
                if item[0][0:l-2] ==# a:key | return item | endif
            else
                if item[0] ==# a:key | return item | endif
            endif
        endif
    endfo
endf
" }}}

fun! s:copy() dict
    let another = copy(self)
    let another.items = copy(self.items)
    return another
endf

" Strip the ALT-key {{{
if has('nvim')
    fun! s:strip_alt(c)
        let k = type(a:c) == type(0) ? nr2char(a:c): a:c
        return len(k) > 1 ? split(k, '.\zs')[-1]: k
    endf
else
    fun! s:strip_alt(c)
        if type(a:c) == type(0)
            let n = a:c
            return nr2char(n > 127 ? n - 128 : n)
        endif
        return a:c
    endf
endif
" }}}

" Create a new popup menu {{{
fun! pmenu#new(name, ...)
    return {
        \ 'name': a:name, 'items': copy(a:000),
        \ 'popup': funcref('s:popup'),
        \ 'prompt': funcref('s:prompt'),
        \ 'merge': funcref('s:merge'),
        \ 'copy': funcref('s:copy'),
        \ 'add_item': funcref('s:add_item'),
        \ }
endf
" }}}
