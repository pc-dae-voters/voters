package mn.dae.pc.voters;

import io.swagger.v3.oas.annotations.OpenAPIDefinition;
import io.swagger.v3.oas.annotations.servers.Server;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.openfeign.EnableFeignClients;

@SpringBootApplication
@EnableFeignClients
@Slf4j
@OpenAPIDefinition(servers = {@Server(description = "service root path", url = "/voters")})
public class VotersServiceApplication {

  public static void main(String[] args) {
    SpringApplication.run(VotersServiceApplication.class, args);
  }
}
