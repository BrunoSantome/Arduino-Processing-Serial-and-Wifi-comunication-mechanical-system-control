
#include <PubSubClient.h>
#include <WiFi101.h>
#include "arduino_secrets.h"
#include <Adafruit_Sensor.h>
#include <DHT.h>
#include <DHT_U.h>
#include <string.h>


//////Hay que añadir el nombre del router y contraseña en el archivo tab/arduino_secrets.h
char ssid[] = SECRET_SSID;    // your network SSID (name)
char pass[] = SECRET_PASS;    // your network password (use for WPA, or use as key for WEP)


//Variables para establecer el broker y el puerto de datos. 
const char *broker = "test.mosquitto.org";
int        port     = 1883; //NON ECRYPTED DATA!!!! ==> si hay tiempo, ver como mandar datos encryptados y desencryptar ==> más profesional. 


//TOPICS del cliente mqtt.
const char *topic_Light  = "/arduino/Sensor/Luz"; //envia
const char *topic_temp = "/arduino/Sensor/temperatura"; //envia

//Topics de las diferentes LEDS
const char *topicLED1 = "/arduino/LED1"; //recibe 
const char *topicLED2 = "/arduino/LED2"; //recibe 
const char *topicLED3 = "/arduino/LED3"; //recibe


//TOPICS contraseña
const char *topic_password = "/arduino/password"; //recibe contraseña
const char *topic_validation_password = "/arduino/password/validation"; //envia validación de contraseña

//TOPICS Motor 
const char *topic_motor_velocidad = "/arduino/Motor/speed";
const char *topic_motor_control = "/arduino/Motor";
const char *topic_motor_direccion = "/arduino/Motor/direccion";


//Variables contraseña
const char *password ="password+";
boolean notification = false;
boolean validPassword = false;



//Variables para almacenar el topic y el mensaje que se recibe
char TopicRecibido[40];
char Mensaje[40];

WiFiClient espClient;
PubSubClient client(espClient);

//Variables para establecer un intervalo de tiempo maximo para el envio y recibo de mensajes. 
const long interval = 2000;
unsigned long previousMillis = 0;
char LightBuffer[50];
char TempBuffer[50];
int count = 0;

//  Variables para las LEDS y el sensor de luz. 
const int lightAnalogSensorPin = A0;
const int LED3 = 1; //Boton
const int LED2 = 2; //temperatura
const int LED1 = 6; //Luz
bool ON = false;


//Variables para el sensor de humedad
#define DHTTYPE DHT11
#define DHT11_PIN 7
DHT_Unified dht(DHT11_PIN, DHTTYPE);

int light;


//Variables para el Motor DC
const int P1A = 4;
const int P2A = 5;
const int enablePin = 3;

int defaultSpeedStep = 150;
const int speedDelay = 1000;

boolean clockWise = true;
boolean anticlockWise = false;

boolean MotorOn = false;

//Función que hace conexión con
void setupWifi(){
  // intentamos conectarnos al wifi
  
  
  while (WiFi.begin(ssid, pass) != WL_CONNECTED) {
    // failed, retry
    Serial.println("Fallo de conexión, reintentando");
    Serial.print(".");
    delay(3000);
  }
  Serial.println("Attempting to connect to WPA SSID: ");
  Serial.println(ssid);
  
  Serial.println("You're connected to the network");
  Serial.println();
}

//Conexión MQTT
void reconnect(){
  while(!client.connected()){
    Serial.println("\nConnecting to:");
    Serial.println(broker);
    //Nos conectamos al broker como cliente
    if (client.connect("Bruno Santome")){          
      Serial.println("subscribing to topic");
      Serial.println(topicLED1);
      Serial.println(topicLED2);
      Serial.println(topicLED3);
      Serial.println(topic_password);
      Serial.println(topic_motor_control);
      Serial.println(topic_motor_velocidad);
      Serial.println(topic_motor_direccion);
      //Nos subscribimos a los distintos canales de telemetria, para que el arduino escuche
      client.subscribe(topicLED1); //Se conecta al topic donde recibira la info de la LED
      client.subscribe(topicLED2);
      client.subscribe(topicLED3);
      client.subscribe(topic_password);
      client.subscribe(topic_motor_control);
      client.subscribe(topic_motor_velocidad);
      client.subscribe(topic_motor_direccion);
      
    } else {
       Serial.print("\nTrying connect again");
       delay(5000);
    }
  }
}

//Con esta función podemos interpretar y meter en un buffer el mensaje que recibimos
void callback(char* topic, byte* payload, unsigned int length) {

  memcpy(Mensaje, payload, length);
  Mensaje[length] = '\0'; 
  strcpy(TopicRecibido,topic);
  notification = true;
}


//Función setup donde declaramos los PINES OUTPUT
void setup() {
  Serial.begin(9600);
  //definimos el broker con el puerto 1883
  client.setServer(broker,port);
  //Nos conectamos al wifi
  setupWifi();
  client.setCallback(callback);
  pinMode(LED1, OUTPUT);
  pinMode(LED2 ,OUTPUT);
  pinMode(LED3, OUTPUT);
  pinMode (P1A,OUTPUT);
  pinMode (P2A,OUTPUT);
  pinMode (enablePin,OUTPUT);

  //Valores iniciales del motor DC
  digitalWrite(P1A, LOW);
  digitalWrite(P2A, LOW);
  analogWrite(enablePin, 0); 

  //Arrancamos el sensor de temperatura/humedad
  dht.begin();

}


void loop() {


  //hasta que no se conecta, no continua con el resto del codigo. 
  if(!client.connected()){
    reconnect();
  }
  client.loop();
  //Estado inicial de las luces, ver si cambiar. 
  if(ON == false){
 
  digitalWrite(LED1,HIGH);
  digitalWrite(LED2,HIGH);
  digitalWrite(LED3,LOW);
  ON = true;
  }
  
  //De momento solo tendrá modo wifi, 

  //Condiciones de motor, si contraseña correcta, nivel de luz suficiente, led azul encendida ==> se puede activar el motor/ configurarlo.
  unsigned long currentMillis = millis();
  //Establecemos un tiempo concreto para el envio de mensajes
  if (currentMillis - previousMillis >= interval) {
            
           //Cogemos el valor del photoresistor y lo metemos en su buffer correspondiente
           //CAMBIAR RESISTENCIA PHOTORESISTOR
           light = analogRead(lightAnalogSensorPin);
           snprintf(LightBuffer,75,"%ld",light);
            Serial.print("Sending Light Value: ");
           Serial.println(LightBuffer);
           
         //Cogemos el valor del sensor de temperatura y lo metemos en su buffer correspondiente
         sensors_event_t event;
         dht.temperature().getEvent(&event);
             //Si es null, salta mensaje de error
             if (isnan(event.temperature)) {
              Serial.println(F("Error reading temperature!"));
            }
            else {
              
              Serial.print(F("Sending Temperature Value: "));
              float t = event.temperature;
              Serial.print (t);
              Serial.println(F("°C"));
              sprintf(TempBuffer, "%.2f", t);
            }
         //Publicamos por sus canales asignados la información leida de los sensores
         client.publish(topic_Light,LightBuffer);
         client.publish(topic_temp,TempBuffer);
         
         previousMillis = currentMillis;
         delay(500);
  }
  
  //Gestión de notificaciones
  if(notification == true){
    notification = false; //Mirar si se puede poner más bonito
    //Siempre miramos por que Topic se ha recibido el mensaje y en función de cual, se hace una cosa u otra
    Serial.print("Received a message with topic ");
    Serial.println(TopicRecibido);
    Serial.println("CONTENT OF MESSAGE:");
    Serial.print(Mensaje);
    Serial.println();

    //Si el topic es el de la LED1 y el valor del mensaje es ON/OFF ==> Encendemos/Apagamos la luz correspondiente
    if(strcmp(TopicRecibido, topicLED1)==0){
     
      if (strcmp(Mensaje, "ON") == 0){
       
          digitalWrite(LED1,HIGH);
          delay(50);
      }
       if (strcmp(Mensaje, "OFF") == 0){
          digitalWrite(LED1,LOW);
          delay(50);
      }
    }
     //Si el topic es el de la LED2 y el valor del mensaje es ON/OFF ==> Encendemos/Apagamos la luz correspondiente
    if(strcmp(TopicRecibido, topicLED2)==0){
     
      if (strcmp(Mensaje, "ON") == 0){
       
          digitalWrite(LED2,HIGH);
           delay(50);
      }
       if (strcmp(Mensaje, "OFF") == 0){
          digitalWrite(LED2,LOW);
           delay(50);
      }
    }
    //Si el topic es el de la LED3 y el valor del mensaje es ON/OFF ==> Encendemos/Apagamos la luz correspondiente
    if(strcmp(TopicRecibido, topicLED3)==0){
     
      if (strcmp(Mensaje, "ON") == 0){
       
          digitalWrite(LED3,HIGH);
           delay(50);
      }
       if (strcmp(Mensaje, "OFF") == 0){
          digitalWrite(LED3,LOW);
           delay(50);
      }
    }
    //Como hemos visto arriba la contraseña esta fijada en una variable. 
    //En caso de que el topic sea el de la contraseña y la contraseña enviada desde la interfaz es igual a la contraseña asignada en la variable
    //Enviamos un mensaje de "OK" por el topic de validación de contraseña, en caso de que sea incorrecta envia el mensaje "wrong password".
 
    if(strcmp(TopicRecibido, topic_password)==0){
        if (strcmp(Mensaje,password) == 0){
            validPassword = true;
            Serial.println("Contraseña correcta");
            client.publish(topic_validation_password,"OK");
        }
        else{
            Serial.println("Contraseña incorrecta");
            validPassword = false;
            client.publish(topic_validation_password,"wrong password");
           
        }
    delay(1000);
  }
     //Control y Monitorización del motor
     if(strcmp(TopicRecibido, topic_motor_control)==0){
         //Si el mensjae es "ON" encendemos el motor, por defecto gira en sentido horario, es decir, que la primera vez siempre girara en sentido horario. 
         if (strcmp(Mensaje, "ON") == 0){
            if(clockWise == true){
              MotorOn = true;
              digitalWrite(P1A, HIGH);
              digitalWrite(P2A, LOW);
              //Notese que se envie una variable de revoluciones del motor por defecto. Esta variable es igual al valor minimo que el motor puede girar
              analogWrite(enablePin, defaultSpeedStep);
              anticlockWise = false;
            delay(50);
            }
            //En caso de que este activo el valor antihorario, este girara en el otro sentido
            if(anticlockWise == true){
              MotorOn = true;
              digitalWrite(P1A, LOW);
              digitalWrite(P2A, HIGH);
              analogWrite(enablePin, defaultSpeedStep);
              clockWise = false;
           
            delay(50);
            }
         }
         //Apagamos el motor en caso de mensjae de "OFF"
          if (strcmp(Mensaje, "OFF") == 0){
              MotorOn = false;
              digitalWrite(P1A, LOW);
              digitalWrite(P2A, LOW);
              analogWrite(enablePin, 0); 
            delay(50);
         }
      
     }
     //Si enviamos una cierta velocidad vamos a actualizar el valor de defaultSpeedStep por el valor recibido. 
     if(strcmp(TopicRecibido, topic_motor_velocidad)==0){    
          Serial.println("Speed Updated: ");
         defaultSpeedStep = atoi(Mensaje);
         //Si el motor esta encendido se cambia mientras este, este encendio  sin necesidad de apagar el motor. 
         if(MotorOn == true) {
          
            analogWrite(enablePin, defaultSpeedStep);
          }
        }
        
     //Aqui gestionamos la dirección del motor
     //Hay dos direcciones: Sentido Horario y Sentido AntiHorario. 
     if(strcmp(TopicRecibido, topic_motor_direccion)==0){
          //Si el mensaje recibido por el topic de dirección es sentido horario
          //Si ya esta en sentido horario, no ocurre nada, salta mensaje avisando
         if (strcmp(Mensaje, "ClockWise") == 0){
            if(MotorOn == true and clockWise == true){
              Serial.println("The Motor is already spinning in ClockWise direction");
              //Si el motor esta girando en sentido anti-horario, lo cambiamos a horario
            } if(MotorOn == true and clockWise == false){
              digitalWrite(P1A, HIGH);
              digitalWrite(P2A, LOW);
              analogWrite(enablePin, defaultSpeedStep);
              clockWise = true;
              anticlockWise = false;
              
            }
            //Si el motor esta pausado, lo cambiamos tambien. Para que al encenderlo, se encienda en sentido horario. 
            if(MotorOn == false){
              anticlockWise = false;
              clockWise = true;  
              
            }
         }
         //Igual que el sentido horario.
         if (strcmp(Mensaje, "AntiClockWise") == 0){
          //Si el mensaje recibido por el topic de dirección es sentido anti-horario
          //Si ya esta en sentido anti-horario, no ocurre nada, salta mensaje avisando
           if(MotorOn == true and anticlockWise == true){
              Serial.println("The Motor is already spinning in AntiClockWise direction");
           //Si el motor esta girando en sentido horario, lo cambiamos a anti-horario
           }if(MotorOn == true and anticlockWise == false){
              digitalWrite(P1A, LOW);
              digitalWrite(P2A, HIGH);
              analogWrite(enablePin, defaultSpeedStep);
              anticlockWise = true;
              clockWise = false;  
            }
            //Si el motor esta pausado, lo cambiamos tambien. Para que al encenderlo, se encienda en sentido anti-horario. 
            if(MotorOn == false){
              anticlockWise = true;
              clockWise = false;
            }
         }
     }

     
  }
}
