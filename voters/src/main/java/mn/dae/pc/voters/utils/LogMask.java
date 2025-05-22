package mn.dae.pc.voters.utils;

import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.pattern.CompositeConverter;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/** This class manages the masking of sensitive data in log record. */
public class LogMask extends CompositeConverter<ILoggingEvent> {

  private static final Pattern TOKEN_PATTERN = Pattern.compile("(token:|TOKEN:|Token:)([^,\\n]*)");

  /**
   * This is called by the logger to allow masking of sensitive data. The configuration can be found
   * in the 'logback.xml' file. It is currently configured to mask GitHub Tokens.
   */
  @Override
  protected String transform(ILoggingEvent event, String in) {
    Matcher matcher = TOKEN_PATTERN.matcher(in);
    StringBuffer sb = new StringBuffer();

    while (matcher.find()) {
      String maskedValue = matcher.group(1) + "******"; // Mask sensitive data
      matcher.appendReplacement(sb, maskedValue);
    }
    matcher.appendTail(sb);

    return sb.toString();
  }
}
