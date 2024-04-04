//
//  DebugPageView.swift
//  Helium
//
//  Created by Fuuko on 2024/3/24.
//

import SwiftUI

// MARK: Debug Page View

struct DebugPageView: View {
    @State private var inputText = ""

    var body: some View {
        NavigationView {
            VStack {
                if DEBUG_MODE_ENABLED {
                    TextEditor(text: $inputText)
                        // .frame(width: 300, height: 300)
                        // .border(.black)
                        .onAppear {
                            inputText = ""
                            // DispatchQueue.global().async {
                            //     inputText += "geo: \(WeatherUtils.getGeocodeByName("南昌 红谷滩"))"
                            // }
                            // let weatherController = TWCWeather.sharedInstance()
                            // weatherController!.locale = Locale.current
                            // weatherController!.updateModel()
                            // inputText = "温度: \(weatherController!.temperature())\n"
                            // inputText += "体感温度: \(weatherController!.feelsLike())\n"
                            // inputText += "天气: \(weatherController!.conditionsDescription())\n"
                            // inputText += "最高温度: \(weatherController!.highDescription())\n"
                            // inputText += "最低温度: \(weatherController!.lowDescription())\n"
                            // inputText += "图标: \(weatherController!.conditionsImageName())\n"
                            // inputText += "地区: \(weatherController!.locationName())\n"
                            // inputText += "风速: \(weatherController!.windSpeed())\n"
                            // inputText += "风速2: \(weatherController!.windSpeed(false))\n"
                            // inputText += "风向: \(weatherController!.windDirection())\n"
                            // inputText += "风向2: \(weatherController!.windDirection(true))\n"
                            // inputText += "湿度: \(weatherController!.humidity(true))\n"
                            // inputText += "湿度2: \(weatherController!.humidity())\n"
                            // inputText += "能见度: \(weatherController!.visibility(true))\n"
                            // inputText += "能见度2: \(weatherController!.visibility())\n"
                            // inputText += "降水: \(weatherController!.precipitationNextHour(true))\n"
                            // inputText += "降水2: \(weatherController!.precipitationNextHour(true))\n"
                            // inputText += "降水24: \(weatherController!.precipitationPast24Hours(true))\n"
                            // inputText += "降水24 2: \(weatherController!.precipitationPast24Hours())\n"
                            // inputText += "气压: \(weatherController!.pressure(true))\n"
                            // inputText += "气压2: \(weatherController!.pressure())\n"
                            // inputText += "UVI: \(weatherController!.uvIndex())\n"
                            // inputText += "AQI: \(weatherController!.airQualityIndex())\n"
                            // inputText += "摄氏度: \(!weatherController!.useFahrenheit)\n"
                            // inputText += "公制单位: \(weatherController!.useMetric)\n"
                            // inputText += "语言: \(Locale.current)\n"
                            // inputText += "Locale: \(weatherController!.locale)\n\n"
                            // inputText += "Data: \(weatherController!.weatherData(10))\n\n"
                            // inputText += "City: \(weatherController!.myCity)\n\n"
                            // inputText += "Location: \(weatherController!.todayModel.forecastModel.location.weatherLocationName)\n\n"
                            // inputText += "Model: \(weatherController!.todayModel.forecastModel)\n\n"

                            // let qweather = QWeather.sharedInstance()
                            // qweather!.locale = UserDefaults.standard.string(forKey: "dateLocale", forPath: USER_DEFAULTS_PATH) ?? "en"
                            // qweather!.apiKey = UserDefaults.standard.string(forKey: "weatherApiKey", forPath: USER_DEFAULTS_PATH) ?? ""
                            // qweather!.freeSub = false
                            // qweather!.update("101240109")
                            // inputText += "Data: \(qweather!.getData(10))\n\n"
                            // inputText += "City: \(qweather!.city)\n\n"
                            // inputText += "Now: \(qweather!.now)\n\n"
                            // inputText += "Daily: \(qweather!.daily)\n\n"
                            // inputText += "Hourly: \(qweather!.hourly)\n\n"

                            // DispatchQueue.global().async {
                            //     let colorfulClouds = ColorfulClouds.sharedInstance()
                            //     colorfulClouds!.locale = UserDefaults.standard.string(forKey: "dateLocale", forPath: USER_DEFAULTS_PATH) ?? "en"
                            //     colorfulClouds!.apiKey = UserDefaults.standard.string(forKey: "weatherApiKey", forPath: USER_DEFAULTS_PATH) ?? ""
                            //     colorfulClouds!.update("115.86318387340181,28.71044895")
                            //     inputText += "Data: \(colorfulClouds!.getData(10))\n\n"
                            // }
                            // DispatchQueue.main.async {
                            //     inputText += "Location: \(WeatherUtils.getCurrentLocation())\n\n"
                            // }
                            // inputText += "City: \(qweather!.city)\n\n"
                            // inputText += "Now: \(qweather!.now)\n\n"
                            // inputText += "Daily: \(qweather!.daily)\n\n"
                            // inputText += "Hourly: \(qweather!.hourly)\n\n"

//                            let mediaRemoteManager = MediaRemoteManager.shared()
//
//                            let bundleIdentifier = mediaRemoteManager.getBundleIdentifier{ bundleIdentifier in
//                                inputText += "BundleIdentifier: \(bundleIdentifier)\n"
//                            }

                            // let isPlaying = mediaRemoteManager.getNowPlayingApplicationIsPlaying()
                            // inputText += "isPlaying: \(isPlaying)\n"

                            // DispatchQueue.main.async {
                            //     mediaRemoteManager.getNowPlayingInfo { info in
                            //         // Handle now playing info
                            //         inputText += "Info: \(info)\n"
                            //     }
                            // }

                            // inputText += "Artist: \(info?["kMRMediaRemoteNowPlayingInfoArtist"])\n"
                            // inputText += "Title: \(info?["kMRMediaRemoteNowPlayingInfoTitle"])\n"
                            // inputText += "Album: \(info?["kMRMediaRemoteNowPlayingInfoAlbum"])\n"

                            // inputText += "Bluetooth: \(MusicPlayerUtils.hasBluetoothHeadset())\n"
                            // inputText += "Wired: \(MusicPlayerUtils.hasWiredHeadset())\n"

                            // let lrcString = "[00:20.220]朝起きて 歯を磨いて\n[00:23.330]あっという間に午後10時\n[00:26.450]今日も たくさん 笑ったなぁ\n[00:29.590]たくさん ときめいたなぁ\n[00:32.509]友達と バカみたいに\n[00:35.810]騒いてる 時にも\n[00:38.900]チラチラって目が合う\n[00:42.900]...偶然だよね\n[00:44.860]初恋なんて言えない\n[00:48.150]キャラじゃないんだもんっ！\n[00:51.400]ねえ あしたも会えるよね\n[00:57.210]まぶたを 閉じると\n[01:00.590]キラキラ キミだらけ\n[01:03.850]今日も 楽しかったね\n[01:06.900]あ～ 恋 してんだなぁ\n[01:32.500]おやすみってメールして\n[01:34.970]返事待ち一時間\n[01:38.120]やっぱ脈 ないのかなぁ\n[01:41.200]ひたすら 受信ボタン\n[01:44.450]キミのメール絵文字付き\n[01:47.450]ゆらゆら ハートマーク\n[01:50.620]期待して いいのかなぁ\n[01:53.610]眠れなくなる\n[01:56.240]キミのそばに いると\n[01:59.810]楽しすぎるんだ\n[02:02.940]ねえ 運命なのですか\n[02:08.850]うまれて 初めて\n[02:12.800]ふわふわ\n[02:15.220]いつか 言いたいな\n[02:18.560]ねえ 大好きだよ\n[02:23.780]もう少し 朝が来るよ\n[02:27.870]そろそろ 寝なくちゃだよね\n[02:33.780]またあしたね電話するよ\n[02:37.250]やっぱ さみしいよ\n[02:40.410]もっともっと 隣に いたいから\n[03:11.420]初恋なんて言えない\n[03:14.630]キャラじゃないんだもんっ！\n[03:17.670]ねえ あしたも会えるよね\n[03:23.750]まぶたを閉じると\n[03:26.860]キラキラ キミだらけ\n[03:30.300]今日も 楽しかったね\n[03:33.230]あ～ 恋 してんだなぁ\n[03:42.790]うれしいな うれしい\n[03:45.820]はじめまして こいごころ\n[03:48.829]あした また あえるね\n[03:52.700]おやすみなさい\n[03:55.140]ゆめで すぐ あえるね\n[03:59.829]おやすみなさい"
                            // let parser = LRCLyricsParser.shared()!
                            // parser.parseLRCString(lrcString)
                            // inputText += "lyrics: \(parser.lyricsDictionary)\n"
                        }
                }
            }
            .padding(5)
            .navigationTitle(Text(NSLocalizedString("Debug", comment: "")))
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

#Preview {
    DebugPageView()
}
