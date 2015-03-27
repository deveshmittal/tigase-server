package tigase.kernel.core;

import tigase.kernel.KernelException;
import tigase.kernel.core.BeanConfig.State;

public class BeanConfigBuilder {

	private BeanConfig beanConfig;

	private Object beanInstance;

	private final String beanName;

	private final DependencyManager dependencyManager;

	private BeanConfig factoryBeanConfig;

	private final Kernel kernel;

	BeanConfigBuilder(Kernel kernel, DependencyManager dependencyManager, String beanName) {
		this.kernel = kernel;
		this.dependencyManager = dependencyManager;
		this.beanName = beanName;
	}

	public BeanConfigBuilder asClass(Class<?> cls) {
		if (this.beanConfig != null)
			throwException(new KernelException("Class or instance is already defined for bean '" + beanName + "'"));

		this.beanConfig = dependencyManager.createBeanConfig(kernel, beanName, cls);
		return this;
	}

	public BeanConfigBuilder asInstance(Object bean) {
		if (this.beanConfig != null)
			throwException(new KernelException("Class or instance is already defined for bean '" + beanName + "'"));

		this.beanConfig = dependencyManager.createBeanConfig(kernel, beanName, bean.getClass());
		this.beanInstance = bean;
		return this;
	}

	public void exec() {
		if (factoryBeanConfig != null) {
			kernel.unregisterInt(factoryBeanConfig.getBeanName());
			dependencyManager.register(factoryBeanConfig);
		}
		kernel.unregisterInt(beanConfig.getBeanName());
		dependencyManager.register(beanConfig);

		if (beanInstance != null) {
			kernel.getBeanInstances().put(beanConfig, beanInstance);
			if (beanInstance instanceof Kernel) {
				((Kernel) beanInstance).setParent(kernel);
			}
			beanConfig.setState(State.initialized);
		}

		kernel.currentlyUsedConfigBuilder = null;
		kernel.injectIfRequired(beanConfig);
	}

	public BeanConfigBuilder exportable() {
		beanConfig.setExportable(true);
		return this;
	}

	public String getBeanName() {
		return beanName;
	}

	protected void throwException(KernelException e) {
		kernel.currentlyUsedConfigBuilder = null;
		throw e;
	}

	public BeanConfigBuilder withFactory(Class<?> beanFactoryClass) {
		if (beanInstance != null)
			throwException(new KernelException("Cannot register factory to bean '" + beanName + "' registered as instance."));
		if (factoryBeanConfig != null)
			throwException(new KernelException("Factory for bean '" + beanName + "' is already registered."));

		this.factoryBeanConfig = dependencyManager.createBeanConfig(kernel, beanName + "#FACTORY", beanFactoryClass);
		beanConfig.setFactory(factoryBeanConfig);

		return this;
	}

}