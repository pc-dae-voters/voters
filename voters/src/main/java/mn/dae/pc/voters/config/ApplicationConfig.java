package mn.dae.pc.voters.config;

import lombok.AllArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestTemplate;

/** Portal service application configuration. */
@Configuration
@AllArgsConstructor
public class ApplicationConfig {

  /**
   * Creates a RestTemplate Bean
   *
   * @return restTemplate.
   */
  @Bean
  public RestTemplate restTemplate() {
    return new RestTemplate();
  }
}
