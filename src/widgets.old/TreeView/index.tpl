<section class="TreeItem {if $root}RootTreeItem{/if}{if !$head} Leaf{/if}">
    {if $head}<hgroup>{$head}</hgroup>{/if}
    <div class="TreeItemBody">
    {$body}
    </div>
</section>
