<tr class="listItem" data-id="{$item[$idField]}" data-list-index="{$index}"
{foreach $item as $key=>$val}{if $key!=$dataField && $key!=$idField}data-{$key}="{$val}"{/if}{/foreach}>
<td>{$item[$dataField]}</td></tr>