import java.io.File;

import javax.inject.Inject;

import org.daisy.maven.xproc.xprocspec.XProcSpecRunner;

import static org.daisy.pipeline.pax.exam.Options.calabashConfigFile;
import static org.daisy.pipeline.pax.exam.Options.domTraversalPackage;
import static org.daisy.pipeline.pax.exam.Options.felixDeclarativeServices;
import static org.daisy.pipeline.pax.exam.Options.logbackBundles;
import static org.daisy.pipeline.pax.exam.Options.logbackConfigFile;
import static org.daisy.pipeline.pax.exam.Options.spiflyBundles;
import static org.daisy.pipeline.pax.exam.Options.thisBundle;
import static org.daisy.pipeline.pax.exam.Options.xprocspecBundles;

import org.junit.Test;
import org.junit.runner.RunWith;

import static org.junit.Assert.assertTrue;

import org.ops4j.pax.exam.Configuration;
import org.ops4j.pax.exam.junit.PaxExam;
import org.ops4j.pax.exam.Option;
import org.ops4j.pax.exam.spi.reactors.ExamReactorStrategy;
import org.ops4j.pax.exam.spi.reactors.PerClass;
import org.ops4j.pax.exam.util.PathUtils;

import static org.ops4j.pax.exam.CoreOptions.junitBundles;
import static org.ops4j.pax.exam.CoreOptions.mavenBundle;
import static org.ops4j.pax.exam.CoreOptions.options;

@RunWith(PaxExam.class)
@ExamReactorStrategy(PerClass.class)
public class DotifyCalabashTest {
	
	@Configuration
	public Option[] config() {
		return options(
			logbackConfigFile(),
			calabashConfigFile(),
			domTraversalPackage(),
			logbackBundles(),
			felixDeclarativeServices(),
			spiflyBundles(),
			mavenBundle().groupId("org.daisy.libs").artifactId("jing").versionAsInProject(),
			mavenBundle().groupId("org.daisy.libs").artifactId("brailleutils-core").versionAsInProject(),
			mavenBundle().groupId("org.daisy.dotify").artifactId("dotify.api").versionAsInProject(),
			mavenBundle().groupId("org.daisy.dotify").artifactId("dotify.common").versionAsInProject(),
			mavenBundle().groupId("org.daisy.dotify").artifactId("dotify.formatter.impl").versionAsInProject(),
			mavenBundle().groupId("org.daisy.pipeline.modules.braille").artifactId("common-java").versionAsInProject(),
			mavenBundle().groupId("org.daisy.pipeline.modules.braille").artifactId("pef-calabash").versionAsInProject(),
			mavenBundle().groupId("org.daisy.pipeline.modules.braille").artifactId("pef-saxon").versionAsInProject(),
			mavenBundle().groupId("org.daisy.pipeline.modules.braille").artifactId("pef-to-html").versionAsInProject(),
			mavenBundle().groupId("org.daisy.pipeline.modules.braille").artifactId("pef-utils").versionAsInProject(),
			xprocspecBundles(),
			thisBundle(),
			junitBundles()
		);
	}
	
	@Inject
	private XProcSpecRunner xprocspecRunner;
		
	@Test
	public void runXProcSpec() throws Exception {
		File baseDir = new File(PathUtils.getBaseDir());
		boolean success = xprocspecRunner.run(new File(baseDir, "src/test/xprocspec"),
		                                      new File(baseDir, "target/xprocspec-reports"),
		                                      new File(baseDir, "target/surefire-reports"),
		                                      new File(baseDir, "target/xprocspec"),
		                                      new XProcSpecRunner.Reporter.DefaultReporter());
		assertTrue("XProcSpec tests should run with success", success);
	}
}
