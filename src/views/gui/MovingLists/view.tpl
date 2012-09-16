{$i=0}
<table id="{$id}">
    <tr>
        {foreach $lists as $list}
        <td>
            <div><h3>{$list.header}</h3></div>
            <div class="listSelect" id="{$id}_LC_{$i}">
            </div>
        </td>
        {if !$list@last}
            <td>
                <div>
                    <button id="{$id}_ADD_{$i}">&gt;&gt;</button><br>
                    <button id="{$id}_DEL_{$i}">&lt;&lt;</button>
                </div>
            </td>
        {/if}
        {++$i}
        {/foreach}
    </tr>
</table>