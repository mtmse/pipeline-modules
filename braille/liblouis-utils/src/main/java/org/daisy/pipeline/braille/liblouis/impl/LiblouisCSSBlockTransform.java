package org.daisy.pipeline.braille.liblouis.impl;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.net.URI;
import javax.xml.namespace.QName;

import com.google.common.base.MoreObjects;
import com.google.common.base.MoreObjects.ToStringHelper;
import com.google.common.collect.ImmutableMap;
import com.google.common.collect.Maps;

import static com.google.common.collect.Iterables.filter;

import com.xmlcalabash.core.XProcRuntime;
import com.xmlcalabash.runtime.XAtomicStep;

import cz.vutbr.web.css.Declaration;
import cz.vutbr.web.css.TermIdent;

import static org.daisy.common.file.URIs.asURI;

import org.daisy.braille.css.InlineStyle;
import org.daisy.braille.css.RuleTextTransform;
import org.daisy.common.file.URLs;
import org.daisy.common.saxon.SaxonInputValue;
import org.daisy.common.transform.InputValue;
import org.daisy.common.transform.Mult;
import org.daisy.common.transform.SingleInSingleOutXMLTransformer;
import org.daisy.common.transform.TransformerException;
import org.daisy.common.transform.XMLInputValue;
import org.daisy.common.transform.XMLOutputValue;
import org.daisy.common.xproc.calabash.XProcStep;
import org.daisy.common.xproc.calabash.XProcStepProvider;

import org.daisy.pipeline.braille.common.AbstractBrailleTranslator;
import org.daisy.pipeline.braille.common.AbstractTransformProvider;
import org.daisy.pipeline.braille.common.AbstractTransformProvider.util.Function;
import org.daisy.pipeline.braille.common.AbstractTransformProvider.util.Iterables;
import org.daisy.pipeline.braille.common.BrailleTranslator;
import org.daisy.pipeline.braille.common.BrailleTranslatorProvider;
import org.daisy.pipeline.braille.common.calabash.CxEvalBasedTransformer;
import static org.daisy.pipeline.braille.common.AbstractTransformProvider.util.Iterables.transform;
import static org.daisy.pipeline.braille.common.AbstractTransformProvider.util.logCreate;
import static org.daisy.pipeline.braille.common.AbstractTransformProvider.util.logSelect;
import org.daisy.pipeline.braille.common.Query;
import org.daisy.pipeline.braille.common.Query.Feature;
import org.daisy.pipeline.braille.common.Query.MutableQuery;
import static org.daisy.pipeline.braille.common.Query.util.mutableQuery;
import org.daisy.pipeline.braille.common.TransformProvider;
import static org.daisy.pipeline.braille.common.TransformProvider.util.dispatch;
import static org.daisy.pipeline.braille.common.TransformProvider.util.memoize;
import org.daisy.pipeline.braille.common.util.Function0;
import org.daisy.pipeline.braille.common.util.Functions;
import org.daisy.pipeline.braille.liblouis.LiblouisTranslator;

import org.osgi.service.component.annotations.Activate;
import org.osgi.service.component.annotations.Component;
import org.osgi.service.component.annotations.Reference;
import org.osgi.service.component.annotations.ReferenceCardinality;
import org.osgi.service.component.annotations.ReferencePolicy;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import org.w3c.dom.Document;
import org.w3c.dom.Node;

public interface LiblouisCSSBlockTransform {
	
	@Component(
		name = "org.daisy.pipeline.braille.liblouis.impl.LiblouisCSSBlockTransform.Provider",
		service = {
			BrailleTranslatorProvider.class,
			TransformProvider.class
		}
	)
	public class Provider extends AbstractTransformProvider<BrailleTranslator> implements BrailleTranslatorProvider<BrailleTranslator> {
		
		private URI href;
		
		@Activate
		protected void activate(final Map<?,?> properties) {
			href = asURI(URLs.getResourceFromJAR("xml/transform/liblouis-block-translate.xpl", LiblouisCSSBlockTransform.class));
		}
		
		private final static Iterable<BrailleTranslator> empty = Iterables.<BrailleTranslator>empty();
		
		protected Iterable<BrailleTranslator> _get(Query query) {
			final MutableQuery q = mutableQuery(query);
			for (Feature f : q.removeAll("input"))
				if ("html".equals(f.getValue().get())) {}
				else if (!"css".equals(f.getValue().get()))
					return empty;
			boolean braille = false;
			final boolean htmlOut; {
				boolean html = false;
				for (Feature f : q.removeAll("output"))
					if ("css".equals(f.getValue().get())) {}
					else if ("html".equals(f.getValue().get()))
						html = true;
					else if ("braille".equals(f.getValue().get()))
						braille = true;
					else
						return empty;
				htmlOut = html;
			}
			final String locale = q.containsKey("locale") ? q.getOnly("locale").getValue().get() : null;
			if (q.containsKey("translator"))
				if (!"liblouis".equals(q.removeOnly("translator").getValue().get()))
					return empty;
			q.add("input", "text-css");
			if (braille)
				q.add("output", "braille");
			Iterable<LiblouisTranslator> translators = logSelect(q, liblouisTranslatorProvider);
			return transform(
				translators,
				new Function<LiblouisTranslator,BrailleTranslator>() {
					public BrailleTranslator _apply(LiblouisTranslator translator) {
						return __apply(
							logCreate(new TransformImpl(translator, htmlOut, locale, q))
						);
					}
				}
			);
		}
			
		@Override
		public ToStringHelper toStringHelper() {
			return MoreObjects.toStringHelper("o.d.p.b.liblouis.impl.LiblouisCSSBlockTransform$Provider");
		}
		
		private class TransformImpl extends AbstractBrailleTranslator implements XProcStepProvider {
			
			private final Query mainQuery;
			private final LiblouisTranslator mainTranslator;
			private final Map<String,String> options;
			
			private TransformImpl(LiblouisTranslator translator, boolean htmlOut, String mainLocale, Query query) {
				options = ImmutableMap.of(// This will omit the <_ style="text-transform:none">
				                          // wrapper. It is assumed that if (output:html) is set, the
				                          // result is known to be braille (which is the case if
				                          // (output:braille) is also set).
				                          "no-wrap", String.valueOf(htmlOut),
				                          "main-locale", mainLocale != null ? mainLocale : "");
				mainTranslator = translator;
				mainQuery = query;
			}
			
			@Override
			public XProcStep newStep(XProcRuntime runtime, XAtomicStep step) {
				return XProcStep.of(
					new SingleInSingleOutXMLTransformer() {
						public Runnable transform(XMLInputValue<?> source, XMLOutputValue<?> result, InputValue<?> params) {
							return () -> {
								if (!(source instanceof SaxonInputValue))
									throw new IllegalArgumentException();
								Mult<SaxonInputValue> mult = ((SaxonInputValue)source).mult(2);
								// analyze the input
								Map<String,Query> subTranslators
									= readTextTransformRules(
										mult.get().ensureSingleItem().asNodeIterator().next(),
										mainQuery);
								BrailleTranslator compoundTranslator;
								Function0<Void> evictTempTranslator; {
									if (subTranslators != null) {
										compoundTranslator = new CompoundTranslator(
											mainTranslator,
											Maps.transformValues(
												subTranslators,
												q -> () -> liblouisTranslatorProvider.get(q).iterator().next()));
										evictTempTranslator = Provider.this.provideTemporarily(compoundTranslator);
									} else {
										compoundTranslator = mainTranslator;
										evictTempTranslator = Functions.noOp;
									}
								}
								// run the transformation
								new CxEvalBasedTransformer(
									href,
									null,
									ImmutableMap.<String,String>builder()
									            .putAll(options)
									            .put("text-transform",
									                 mutableQuery().add("id", compoundTranslator.getIdentifier()).toString())
									            .build()
								).newStep(runtime, step).transform(
									ImmutableMap.of(
										new QName("source"), mult.get(),
										new QName("parameters"), params),
									ImmutableMap.of(
										new QName("result"), result)
								).run();
								evictTempTranslator.apply();
							};
						}
					},
					runtime
				);
			}
			
			@Override
			public ToStringHelper toStringHelper() {
				return MoreObjects.toStringHelper("o.d.p.b.liblouis.impl.LiblouisCSSBlockTransform$Provider$TransformImpl")
					.add("translator", mainTranslator);
			}
		}
		
		private Map<String,Query> readTextTransformRules(Node doc, Query mainQuery) {
			if (!(doc instanceof Document))
				throw new TransformerException(new IllegalArgumentException());
			Map<String,Query> queries = null;
			String style = (((Document)doc).getDocumentElement()).getAttribute("style");
			if (style != null && !"".equals(style))
				for (RuleTextTransform rule : filter(new InlineStyle(style), RuleTextTransform.class))
					for (Declaration d : rule)
						if (d.getProperty().equals("system")
						    && d.size() == 1
						    && d.get(0) instanceof TermIdent
						    && "braille-translator".equals(((TermIdent)d.get(0)).getValue())) {
							MutableQuery query = mutableQuery(mainQuery);
							for (Declaration dd : rule)
								if (dd.getProperty().equals("system")
								    && dd.size() == 1
								    && dd.get(0) instanceof TermIdent
								    && "braille-translator".equals(((TermIdent)dd.get(0)).getValue()))
									;
								else if (!dd.getProperty().equals("system")
								         && dd.size() == 1
								         && dd.get(0) instanceof TermIdent) {
									String key = dd.getProperty();
									String value = ((TermIdent)dd.get(0)).getValue();
									if (query.containsKey(key))
										query.removeAll(key);
									query.add(key, value);
									if (key.equals("contraction") && value.equals("no"))
										query.removeAll("grade");
								} else {
									query = null;
									break;
								}
							if (queries == null) queries = new HashMap<>();
							queries.put(rule.getName(), query);
							break;
						}
			return queries;
		}
		
		@Reference(
			name = "LiblouisTranslatorProvider",
			unbind = "unbindLiblouisTranslatorProvider",
			service = LiblouisTranslator.Provider.class,
			cardinality = ReferenceCardinality.MULTIPLE,
			policy = ReferencePolicy.DYNAMIC
		)
		protected void bindLiblouisTranslatorProvider(LiblouisTranslator.Provider provider) {
			liblouisTranslatorProviders.add(provider);
			logger.debug("Adding LiblouisTranslator provider: {}", provider);
		}
		
		protected void unbindLiblouisTranslatorProvider(LiblouisTranslator.Provider provider) {
			liblouisTranslatorProviders.remove(provider);
			liblouisTranslatorProvider.invalidateCache();
			logger.debug("Removing LiblouisTranslator provider: {}", provider);
		}
		
		private List<TransformProvider<LiblouisTranslator>> liblouisTranslatorProviders
		= new ArrayList<TransformProvider<LiblouisTranslator>>();
		private TransformProvider.util.MemoizingProvider<LiblouisTranslator> liblouisTranslatorProvider
		= memoize(dispatch(liblouisTranslatorProviders));
		
		private static final Logger logger = LoggerFactory.getLogger(Provider.class);
		
	}
}
