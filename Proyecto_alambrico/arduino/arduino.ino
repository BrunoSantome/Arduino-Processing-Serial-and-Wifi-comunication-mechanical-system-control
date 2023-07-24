#include <Adafruit_Sensor.h>
#include <DHT.h>
#include <DHT_U.h>
#include <string.h>


//Variables contraseña

String message = ""; 
//Variables para establecer un intervalo de tiempo maximo para el envio y recibo de mensajes. 

const long interval = 2000;
unsigned long previousMillis = 0;
char LightBuffer[50];
char TempBuffer[50];
char Mensaje[40];
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
float t;
int temp;

//Variables para el Motor DC
const int P1A = 4;
const int P2A = 5;
const int enablePin = 3;

int defaultSpeedStep = 165;
const int speedDelay = 1000;


boolean clockWise = true;
boolean anticlockWise = false;

boolean LED1IsOn = false;
boolean LED2IsOn = false;
boolean LED3IsOn = false;
boolean MotorIsOn = false;

boolean contact = false;
char GUI_Order = 0;

//Función setup donde declaramos los PINES OUTPUT
void setup() {
  Serial.begin(9600);
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

  if(Serial.available() > 0){/*Wait for GUI to send data*/
    GUI_Order = Serial.read();
    //message = Serial.readStringUntil('\n');
   
    switch(GUI_Order) {
        case '0':
         defaultSpeedStep = 165;
         if(MotorIsOn == true) {
            analogWrite(enablePin, defaultSpeedStep);
          }
       break;
      case '1':
         defaultSpeedStep = 175;
         if(MotorIsOn == true) {
            analogWrite(enablePin, defaultSpeedStep);
          }
       break;
      case '2': 
         defaultSpeedStep = 185;
         if(MotorIsOn == true) {
            analogWrite(enablePin, defaultSpeedStep);
          }
       break;
      case '3': 
        defaultSpeedStep = 195;
         if(MotorIsOn == true) {
            analogWrite(enablePin, defaultSpeedStep);
          }
       break;
      case '4': 
         defaultSpeedStep = 205;
         if(MotorIsOn == true) {
            analogWrite(enablePin, defaultSpeedStep);
          }
       break;
      case '5': 
         defaultSpeedStep = 215; 
         if(MotorIsOn == true) {
            analogWrite(enablePin, defaultSpeedStep);
          }
       break;
      case '6': 
         defaultSpeedStep = 225; 
         if(MotorIsOn == true) {
            analogWrite(enablePin, defaultSpeedStep);
          }
       break;
      case '7': 
         defaultSpeedStep = 235; 
         if(MotorIsOn == true) {
            analogWrite(enablePin, defaultSpeedStep);
          }
       break;
      case '8': 
         defaultSpeedStep = 245; 
         if(MotorIsOn == true) {
            analogWrite(enablePin, defaultSpeedStep);
          }
       break;
      case '9': 
         defaultSpeedStep = 255; 
         if(MotorIsOn == true) {
            analogWrite(enablePin, defaultSpeedStep);
          }
       break;
      case 'X': //ON-OFF Led1
        if(LED1IsOn) digitalWrite(LED1, LOW);
        else digitalWrite(LED1, HIGH);
        LED1IsOn= !LED1IsOn;
        
        break;
      case 'Y': //ON-OFF Led2
        if(LED2IsOn) digitalWrite(LED2, LOW);
        else digitalWrite(LED2, HIGH);
        LED2IsOn = ! LED2IsOn;
  
        break;
      case 'Z': //ON-OFF Led3
      
        if( LED3IsOn) digitalWrite(LED3, LOW);
        else digitalWrite(LED3, HIGH);
        LED3IsOn = !LED3IsOn;
   
        break;
      case 'M': //ON-OFF Motor
        if(MotorIsOn == false){   
          if(clockWise == true){       
              digitalWrite(P1A, HIGH);
              digitalWrite(P2A, LOW);
              analogWrite(enablePin, defaultSpeedStep);
              MotorIsOn = true;       
          }
          if(anticlockWise == true){
              MotorIsOn = true;
              digitalWrite(P1A, LOW);
              digitalWrite(P2A, HIGH);
              analogWrite(enablePin, defaultSpeedStep);
              }
        }
             else {
              MotorIsOn = false;
              digitalWrite(P1A, LOW);
              digitalWrite(P2A, LOW);
              analogWrite(enablePin, 0); 
   
            
        }
        break;
      case 'R': //Motor giro horario
       if(MotorIsOn == true and clockWise == true){
              //Serial.println("The Motor is already spinning in ClockWise direction");
              //Si el motor esta girando en sentido anti-horario, lo cambiamos a horario
            } if(MotorIsOn == true and clockWise == false){
              digitalWrite(P1A, HIGH);
              digitalWrite(P2A, LOW);
              analogWrite(enablePin, defaultSpeedStep);
              clockWise = true;
              anticlockWise = false;
              delay(50);
            }
            //Si el motor esta pausado, lo cambiamos tambien. Para que al encenderlo, se encienda en sentido horario. 
            if(MotorIsOn== false){
              anticlockWise = false;
              clockWise = true;  
             
            }
        break;
       case 'L': //Motor giro anti-horario
            //Si el mensaje recibido por el topic de dirección es sentido anti-horario
           //Si ya esta en sentido anti-horario, no ocurre nada, salta mensaje avisando
           if(MotorIsOn == true and anticlockWise == true){
              Serial.println("The Motor is already spinning in AntiClockWise direction");
           //Si el motor esta girando en sentido horario, lo cambiamos a anti-horario
           }if(MotorIsOn == true and anticlockWise == false){
              digitalWrite(P1A, LOW);
              digitalWrite(P2A, HIGH);
              analogWrite(enablePin, defaultSpeedStep);
              anticlockWise = true;
              clockWise = false;  
            }
            //Si el motor esta pausado, lo cambiamos tambien. Para que al encenderlo, se encienda en sentido anti-horario. 
            if(MotorIsOn == false){
              anticlockWise = true;
              clockWise = false;
            }
       default:
       break;
 
      }
     
     
   }
   
   while (Serial.available() <= 0) {
    light = analogRead(lightAnalogSensorPin);
    sensors_event_t event;
    dht.temperature().getEvent(&event);
    t = event.temperature;
    Serial.print("LIGHT:");
    Serial.println(light);
    delay(150);
    Serial.print("TEMPERATURE:");
    Serial.println(t);
    delay(100);
    
   }

  delay(100);
  

}
