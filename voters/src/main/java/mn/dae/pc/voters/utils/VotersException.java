package mn.dae.pc.voters.utils;

/** An voters Exception */
public class VotersException extends Exception {

  /** Create a new votersException containing an error message and the exception that was caught. */
  public VotersException(String m, Throwable t) {
    super(m, t);
  }
}
