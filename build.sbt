import Dependencies._

lazy val root = (project in file(".")).
  settings(
    inThisBuild(List(
      organization := "com.example",
      scalaVersion := "2.12.4",
      version      := "0.1.0-SNAPSHOT",
    )),
    name := "birdmonger",
    libraryDependencies ++= Seq(twitterServer, slf4jSimple),
    assemblyOutputPath in assembly := new File("lib/birdmonger.jar"),
    assemblyJarName in assembly := "birdmonger.jar",
    assemblyMergeStrategy in assembly := {
      case "BUILD" => MergeStrategy.discard
      case x if x.endsWith("io.netty.versions.properties") => MergeStrategy.first
      case x =>
        val oldStrategy = (assemblyMergeStrategy in assembly).value
        oldStrategy(x)
    },
    assemblyShadeRules in assembly := Seq(
      ShadeRule.rename("com.fasterxml.jackson.**" -> "birdmonger.@0").inAll
    )
  )
