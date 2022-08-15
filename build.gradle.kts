plugins {
    java
    idea
}

val zomboidjar: String by project
val zomboidjarsources: String by project
val zomboidlua: String by project
val zomboidmedia: String by project

dependencies {
    implementation(files(zomboidjar))
    implementation(files(zomboidjarsources))
    implementation(files(zomboidlua))
    implementation(files(zomboidmedia))
}

sourceSets.create("media") {
    java.srcDir("media")

    compileClasspath += sourceSets.main.get().compileClasspath
}
