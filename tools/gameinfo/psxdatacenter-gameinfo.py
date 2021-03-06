#!/bin/env python3

from gameinfo import Gameinfo
from os import makedirs
from os.path import exists, realpath
import re
import requests

def _top_srcdir():
    return realpath(__file__ + '"/../../..')

def _downloaddir():
    return _top_srcdir() + '/tools/gameinfo/download'

def _outdir():
    return _top_srcdir() + '/tools/gameinfo/out'

def _fetch_page(url):
    user_agent = {'User-Agent': 'Gameinfo PlayStation DataCenter Scrapper 1.0'}
    response = requests.get(url, headers=user_agent)

    # Try to decode utf-16
    try:
        page = response.content.decode('utf-16')
        if page.startswith('<html'):
            return page
    except:
        pass

    return response.text

class GamesListScrapper:
    def _parse_game_list_page(page, gameinfo, verbose=False):
        skip = '.*?'
        grab = '(.*?)'

        begin = '<tr>' + skip
        end  = skip + '</tr>'

        info_part = 'col1' + skip + 'href="' + grab + '"'
        id_part = 'col2' + skip + '>' + grab + '</td>'
        title_part = 'col3' + skip + '>&nbsp;' + grab + '</td>'

        game_expr = begin + info_part + skip + id_part + skip + title_part + end

        domain = 'http://psxdatacenter.com/'

        for match in re.finditer(game_expr, page, re.DOTALL):
            disc_ids = match.group(2).split("<br>")

            title = match.group(3).split('<br>')[0]
            title = title.split('&nbsp; -&nbsp;')[0]
            if verbose:
                print("Adding " + " ".join(disc_ids) + ": " + title)

            discs_node = gameinfo.add_game_discs(title, disc_ids)

            discs_node.set('info', domain + match.group(1))
            if '<u>Includes:</u>' in match.group(3):
                includes = match.group(3).split('<u>Includes:</u>')[1].replace('\n', ' ').replace('&nbsp;', ' ').replace('</span>', '')
                includes = re.sub('<span.*?>', '', includes)
                discs_node.set('includes', includes.strip())

    def fetch_tmp_gameinfo(verbose):
        gameinfo = Gameinfo()

        game_lists = [
            'http://psxdatacenter.com/jlist.html',
            'http://psxdatacenter.com/plist.html',
            'http://psxdatacenter.com/ulist.html']

        for url in game_lists:
            page = _fetch_page(url)
            GamesListScrapper._parse_game_list_page(page, gameinfo, verbose)

        return gameinfo

class GamePageScrapper:
    def _get_game_title(game_page):
        title_search = 'Official Title.*?<td.*?>(?:&nbsp;)*(.*?)</td>'
        match = re.search(title_search, game_page, re.DOTALL)
        if not match:
            return None

        title = match.group(1)

        title = title.replace('&nbsp;', ' ')
        title = title.strip()

        return title

    def _get_game_controllers(game_page):
        classic_gamepad_search = 'Standard Controller'
        allow_classic_gamepad = re.search(classic_gamepad_search, game_page, re.IGNORECASE)

        analog_gamepad_search = 'Analog Controller'
        allow_analog_gamepad = re.search(analog_gamepad_search, game_page, re.IGNORECASE)

        controllers = []
        if allow_classic_gamepad:
            controllers.append ('classic-gamepad')
        if allow_analog_gamepad:
            controllers.append ('analog-gamepad')

        return controllers

    def parse_game_page(gameinfo, game, url):
        game_page = _fetch_page(url)

        title = GamePageScrapper._get_game_title(game_page)
        if not title:
            return

        controllers = GamePageScrapper._get_game_controllers(game_page)
        if controllers and len(controllers) == 0:
            controllers = None
        if controllers and len(controllers) == 2:
            if 'classic-gamepad' in controllers and 'analog-gamepad' in controllers:
                controllers = None

        print(title)

        gameinfo.set_game_title(game, title)
        if controllers is not None:
            gameinfo.set_game_controllers(game, controllers)

class Scrapper:
    _FILENAME = 'playstation.gameinfo.xml.in'
    _TMP_FILENAME = _FILENAME + '.tmp'

    def _get_tmp_gameinfo(verbose):
        gameinfo_path = _outdir() + '/' + 'playstation.gameinfo.xml.in.tmp'
        if exists(gameinfo_path):
            return Gameinfo(gameinfo_path)

        gameinfo = GamesListScrapper.fetch_tmp_gameinfo(verbose)

        if not exists(_outdir()):
            makedirs(_outdir())

        gameinfo.save(gameinfo_path)

        return gameinfo

    def scrap(verbose):
        gameinfo = Scrapper._get_tmp_gameinfo(verbose)

        gameinfo_path = _outdir() + '/' + 'playstation.gameinfo.xml.in.tmp'
        if not exists(_outdir()):
            makedirs(_outdir())

        changed = False
        i = 0
        for game in gameinfo.findall('games/game'):
            for discs in game.findall('./discs[@info]'):
                info = discs.get('info')
                if not info:
                    continue

                GamePageScrapper.parse_game_page(gameinfo, game, info)
                changed = True

                del discs.attrib['info']

                i = i + 1
                if i >= 10:
                    gameinfo.save(gameinfo_path)
                    i = 0
        if changed:
            gameinfo.save(gameinfo_path)

if __name__ == '__main__':
    verbose = False
    Scrapper.scrap(verbose)
