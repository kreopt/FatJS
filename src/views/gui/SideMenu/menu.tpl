<menu id="{$menuId}" class="JAFW_MenuList">
    {foreach $items as $item}
    <li data-page="{$item.id}">{$item.name}<span class="Indicator"></span></li>
    {/foreach}
</menu>