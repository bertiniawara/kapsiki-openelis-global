package spring.service.testcodes;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import spring.service.common.BaseObjectServiceImpl;
import us.mn.state.health.lims.testcodes.dao.TestCodeTypeDAO;
import us.mn.state.health.lims.testcodes.valueholder.TestCodeType;

@Service
public class TestCodeTypeServiceImpl extends BaseObjectServiceImpl<TestCodeType, String> implements TestCodeTypeService {
	@Autowired
	protected TestCodeTypeDAO baseObjectDAO;

	TestCodeTypeServiceImpl() {
		super(TestCodeType.class);
	}

	@Override
	protected TestCodeTypeDAO getBaseObjectDAO() {
		return baseObjectDAO;
	}

	@Override
	@Transactional(readOnly = true)
	public TestCodeType getTestCodeTypeById(String id) {
        return getBaseObjectDAO().getTestCodeTypeById(id);
	}

	@Override
	@Transactional(readOnly = true)
	public TestCodeType getTestCodeTypeByName(String name) {
        return getBaseObjectDAO().getTestCodeTypeByName(name);
	}
}