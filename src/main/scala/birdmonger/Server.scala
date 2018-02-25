/*
 * Copyright (c) 2018 Iikka Niinivaara
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you
 * may not use this file except in compliance with the License.  You may
 * obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
 * implied.  See the License for the specific language governing
 * permissions and limitations under the License.
 */

package birdmonger

import java.net.InetSocketAddress

import collection.JavaConverters._
import com.twitter.finagle.{Http, ListeningServer, Service}
import com.twitter.finagle.http.{Request, Response}
import com.twitter.server.TwitterServer
import com.twitter.util.{Await, Future}

object Server extends TwitterServer {
  private val startServer = flag("birdmonger.startServer", true, "Should we actually start listening for connections")
  private val endpoint = flag("birdmonger.endpoint", new InetSocketAddress("localhost", 3000), "Host and port to listen on")
  private val certificatePath = flag[String]("birdmonger.tls.certificatePath", "", "The path to the PEM encoded X.509 certificate chain. Required for TLS")
  private val keyPath = flag[String]("birdmonger.tls.keyPath", "", "The path to the corresponding PEM encoded PKCS#8 private key. Required for TLS")
  private val caCertificatePath = flag[String]("birdmonger.tls.caCertificatePath", "", "The path to the optional PEM encoded CA certificates trusted by this server")
  private val ciphers = flag[String]("birdmonger.tls.ciphers", "", "Ciphers the list of supported ciphers, delimited by `:`")
  private val nextProtocols = flag[String]("birdmonger.tls.nextProtocols", "", "The comma-delimited list of protocols used to perform APN (Application Protocol Negotiation)")
  private var useHTTPS = false

  var handler: (Request, java.util.Map[String, String]) => Response = _

  val service: Service[Request, Response] {
    def apply(request: Request): Future[Response]
  } = new Service[Request, Response] {
    def apply(request: Request): Future[Response] = {
      Future.value(handler(request, request.headerMap.asJava))
    }
  }

  def apply: ListeningServer = {
    var serverConf = Http.server
      .configured(Http.Netty4Impl)

    if (certificatePath.isDefined || keyPath.isDefined) {
      serverConf = serverConf.withTransport.tls(certificatePath(), keyPath(), caCertificatePath.get, ciphers.get, nextProtocols.get)
      useHTTPS = true
    }

    val server = serverConf.serve(endpoint(), service)
    server
  }

  def main(): Unit = {
    if (startServer()) {
      val server: ListeningServer = apply

      onExit {
        server.close()
      }

      Await.ready(server)
    }
  }

  def scheme(): String = {
    if (useHTTPS) {
      "https"
    } else {
      "http"
    }
  }


}
