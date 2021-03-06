package peote.view.utils;

@:generic
class RenderList<T>
{
	public var first(default,null):RenderListItem<T> = null; // first value in list
	public var last(default,null) :RenderListItem<T> = null; // last value in list

	public var itemMap:Map<T,RenderListItem<T>>;
	
	public function new(itemMap:Map<T,RenderListItem<T>>) 
	{
		this.itemMap = itemMap;
	}
	
	public function add(value:T, atValue:T, addBefore:Bool)
	{	
		var newItem:RenderListItem<T> = null;
		
		if (addBefore) // add before element or at start of list
		{
			if (first == null) newItem = first = last = new RenderListItem<T>(value, null, null);
			else
			{
				var newItem:RenderListItem<T>;
				if (atValue == null) {
					newItem = first = new RenderListItem<T>(value, null, first);
				} else {
					var atItem = itemMap.get(atValue);
					if (atItem != null) {						
						newItem = new RenderListItem<T>(value, atItem.prev, atItem);
						if (atItem == first) first = newItem;
					}
					else throw('Error on addDisplay: $atValue is not in Displaylist.');
				}			
			}
		}
		else  // add after element or at end of list
		{
			if (last == null) newItem = first = last = new RenderListItem<T>(value, null, null);
			else
			{
				if (atValue == null) {
					newItem = last = new RenderListItem<T>(value, last, null);
				} else {
					var atItem = itemMap.get(atValue);
					if (atItem != null) {						
						newItem = new RenderListItem<T>(value, atItem, atItem.next);
						if (atItem == last) last = newItem;
					}
					else throw('Error on addDisplay: $atValue is not in Displaylist.');
				}
			}			
		}
		
		var oldItem:RenderListItem<T> = itemMap.get(value);
		if (oldItem != null) removeItem(oldItem);
		itemMap.set(value, newItem);
	} 
	
	public function remove(value:T):Void
	{
		var item:RenderListItem<T> = itemMap.get(value);
		if (item != null) {
			removeItem(item);
			itemMap.remove(value);
		}
		else throw('Error on removeDisplay: $value is not in Displaylist.');
	}
	
	private inline function removeItem(item:RenderListItem<T>):Void {
		if (item == first) first = item.next;
		if (item == last ) last  = item.prev;
		item.remove(); // remove if already exist
	}
}

