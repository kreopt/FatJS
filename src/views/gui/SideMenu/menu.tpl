<menu id="{$menuId}" class="JAFW_MenuList">
    {foreach $items as $item}
    <li data-page="{$item.id}" title="{$item.name}"><img src="static/images/Apps/{$item.id}.svg" alt="{$item.name}"/><span class="Indicator"></span></li>
    {/foreach}
</menu>