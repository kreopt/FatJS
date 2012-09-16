<section class="JAFW_Table">
    <header class="JAFW_TableHeader">
        {$i=0}
        {foreach $header as $row}
        <section class="JAFW_TableRow" data-row="{$i++}">
            {$j=0}
            {foreach $row as $cell}
            <div class="JAFW_Cell {if $cell.className}{$cell.className}{/if}" data-col="{$j++}" {if $width[$j-1]}style="width: {$width[$j-1]};"{/if}>{$cell.html}</div>
            {/foreach}
        </section>
        {/foreach}
    </header>
    <section class="JAFW_TableBody">
        {$i=0}
        {foreach $rows as $row}
        <section class="JAFW_TableRow" data-row="{$i++}">
            {$j=0}
            {foreach $row as $cell}
            <div class="JAFW_Cell {if $cell.className}{$cell.className}{/if}" data-col="{$j++}"
            {if $cell.data}{foreach $cell.data as $key=>$val} data-{$key}="{$val}" {/foreach}{/if}
            {if $width[$j-1]}style="width: {$width[$j-1]};"{/if}>{$cell.html}</div>
            {/foreach}
        </section>
        {/foreach}
    </section>
</section>