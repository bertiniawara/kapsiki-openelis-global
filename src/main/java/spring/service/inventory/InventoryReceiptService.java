package spring.service.inventory;

import java.util.List;

import spring.service.common.BaseObjectService;
import us.mn.state.health.lims.inventory.valueholder.InventoryReceipt;

public interface InventoryReceiptService extends BaseObjectService<InventoryReceipt, String> {
	void getData(InventoryReceipt inventoryReceipt);

	InventoryReceipt getInventoryReceiptById(String id);

	List<InventoryReceipt> getAllInventoryReceipts();

	InventoryReceipt getInventoryReceiptByInventoryItemId(String id);
}