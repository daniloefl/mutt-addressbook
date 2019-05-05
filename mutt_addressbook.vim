" Description: Plugin for writing mail from vim (mutt or others)
" Author:      David Beniamine <David@Beniamine.net>
" License:     Gpl v3.0
" Website:     http://github.com/dbeniamine/vim-mail.vim

if(!has_key(g:VimMailContactsCommands, "mutt_addressbook"))
    let g:VimMailContactsCommands['mutt_addressbook']={ 'query' : "~/workspace/mutt-addressbook/mutt-addressbook.py  ",
                \'sync': ""}
endif

function! vimmail#contacts#mutt_addressbook#sync()
    execute ":! ".g:VimMailContactsCommands['mutt_addressbook']['sync']
endfunction

" Complete function
" If we are on a header field provides only mail information
" Else provides each fields contains in the matched vcards
function! vimmail#contacts#mutt_addressbook#complete(findstart, base)
    if(a:findstart) "first call {{{3
        return vimmail#contacts#startComplete()
    else "Find complete {{{3
        " Set the grep function {{{4
        if (g:VimMailCompleteOnlyMail)
            let l:grep="egrep \"(Name|MAIL)\""
        else
            let l:grep="grep :"
        endif
        let records=[]
        " Do the query {{{4
        let out=vimmail#runcmd(g:VimMailContactsCommands['mutt_addressbook']['query'].
                    \" ".a:base." | ".l:grep)
        for line in out
            if line=~ "Name" "Recover the name {{{5
                let l:name=substitute(split(line, ':')[1],"^[ ]*","","")
            else " parse the answer {{{5
                " mutt_addressbook answer look like this
                " EMAIL (WORK): foo@bar.com
                let ans=split(line,':')
                " Remove useless whitespace
                let ans[1]=substitute(ans[1], "^[ ]*","","")
                let l:item={}
                " Full information for preview window name + mutt_addressbook line
                let l:item.info=l:name.":\n ".line
                if ans[0]=~"^EMAIL"
                    " Put email addresses in '<' '>'
                    let l:item.word=l:name." <".ans[1].">"
                    let l:item.abbr=ans[1]
                    let l:item.kind="M"
                else
                    let l:item.word=ans[1]
                    "Use the first letter of the mutt_addressbook type for the kind
                    let l:item.kind=strpart(ans[0],0,1)
                endif
                " If there are a precise info (aka '(WORK)') add it
                if ans[0]=~"(.*)"
                    let l:item.menu=substitute(ans[0],'\(.*(\|).*\)',"","g")
                endif
                call add(records, item)
            endif
        endfor
        return records
    endif
endfunction


" vim:set et sw=4:
