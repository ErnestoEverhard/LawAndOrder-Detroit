#!/usr/bin/env python3
"""Download the Poly Haven (CC0) assets the Godot scenes use into godot/assets/.

  python3 tools/fetch_assets.py            # fetch everything missing
  python3 tools/fetch_assets.py --list     # show what is present / missing

Layout it writes:
  godot/assets/models/<id>/<id>_1k.gltf (+ .bin and textures/ exactly as the glTF references them)
  godot/assets/textures/<id>/<id>_{diff,nor_gl,rough}_1k.jpg   (names normalised)
  godot/assets/hdri/<id>_2k.hdr
Anything already on disk is skipped, so it is safe to re-run. Standard library only.
"""
import json, os, sys, time, urllib.request

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'godot', 'assets')
UA = {'User-Agent': 'asset-fetch/1.0'}
MAX_MODEL_MB = 14

MODELS = """
metal_office_desk steel_frame_shelves_01 steel_frame_shelves_03 mounted_fluorescent_lights security_camera_01
plastic_monobloc_chair_01 metal_stool_01 office_notepads binder_notebook clipboard stationery_supplies
cardboard_box_01 fire_alarm korean_fire_extinguisher_01 WoodenChair_01 WoodenTable_01 WoodenTable_02
dining_chair_02 Television_01 standing_chalkboard_01 street_lamp_01 street_lamp_02 fire_hydrant
concrete_road_barrier modular_chainlink_fence rollershutter_door hand_truck plastic_crate_01 wooden_crate_01
wooden_crate_02 Barrel_01 trashbag exterior_aircon_unit industrial_wall_lamp caged_hanging_light
hanging_industrial_lamp security_light utility_box_01 covered_car old_tyre modular_electricity_poles
WetFloorSign_01 industrial_storage_cart metal_toolbox metal_tool_chest adjustable_wrench ladder_sectioned_01
wooden_bookshelf_worn decorative_book_set_01 barrel_stove old_bed_frame flood_lights cement_bag Sofa_01
painted_wooden_bench planter_pot_clay dirty_football modular_street_seating korean_public_payphone_01
vintage_suitcase ArmChair_01 GreenChair_01 ClassicConsole_01 fancy_picture_frame_01 mantel_clock_01
medical_box wheelchair_01 ceiling_fan weed_plant_02 grass_medium_01 plastic_thermos cigarette_pack
vintage_electric_kettle vintage_microwave
""".split()

TEXTURES = """
concrete_block_wall asphalt_02 gravel_floor_02 old_linoleum_flooring_01 wooden_panels dark_paneled_wood
marble_tiles terrazzo_tiles corrugated_iron_02 rusty_metal_02 weathered_plank_siding wood_planks_grey
factory_brick ceiling_interior metal_plate painted_concrete square_tiles concrete_pavement leafy_grass
red_brick_03 painted_metal_shutter brown_leather
""".split()

HDRIS = ['freight_station', 'preller_drive']


def get(url, tries=4):
    for i in range(tries):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=60) as r:
                return r.read()
        except Exception as e:  # noqa: BLE001
            if i == tries - 1:
                raise
            time.sleep(2 + i * 3)


def save(path, url):
    if os.path.exists(path) and os.path.getsize(path) > 0:
        return 0
    os.makedirs(os.path.dirname(path), exist_ok=True)
    data = get(url)
    with open(path + '.part', 'wb') as f:
        f.write(data)
    os.replace(path + '.part', path)
    return len(data)


def files(asset):
    return json.loads(get('https://api.polyhaven.com/files/' + asset))


def model(mid):
    d = os.path.join(ROOT, 'models', mid)
    main = os.path.join(d, mid + '_1k.gltf')
    if os.path.exists(main):
        return 'present'
    g = files(mid)['gltf']['1k']['gltf']
    inc = g.get('include', {})
    total = (g.get('size', 0) + sum(v.get('size', 0) for v in inc.values())) / 1e6
    if total > MAX_MODEL_MB:
        return 'SKIPPED (%.1f MB is over the %d MB cap)' % (total, MAX_MODEL_MB)
    for rel, v in inc.items():
        save(os.path.join(d, rel), v['url'])
    save(main, g['url'])            # the glTF last, so a half-fetched model is retried
    return 'fetched %.1f MB' % total


def texture(tid):
    d = os.path.join(ROOT, 'textures', tid)
    f = files(tid)
    out = []
    for key, name in (('Diffuse', 'diff'), ('nor_gl', 'nor_gl'), ('Rough', 'rough')):
        if key not in f:
            return 'FAILED (no %s map)' % key
        out.append(save(os.path.join(d, '%s_%s_1k.jpg' % (tid, name)), f[key]['1k']['jpg']['url']))
    return 'fetched %.1f MB' % (sum(out) / 1e6) if any(out) else 'present'


def hdri(hid):
    n = save(os.path.join(ROOT, 'hdri', hid + '_2k.hdr'), files(hid)['hdri']['2k']['hdr']['url'])
    return 'fetched %.1f MB' % (n / 1e6) if n else 'present'


def main():
    listing = '--list' in sys.argv
    bad = 0
    for kind, ids, fn, probe in (
        ('model', MODELS, model, lambda i: os.path.join(ROOT, 'models', i, i + '_1k.gltf')),
        ('texture', TEXTURES, texture, lambda i: os.path.join(ROOT, 'textures', i, i + '_rough_1k.jpg')),
        ('hdri', HDRIS, hdri, lambda i: os.path.join(ROOT, 'hdri', i + '_2k.hdr')),
    ):
        for i in ids:
            if listing:
                res = 'present' if os.path.exists(probe(i)) else 'MISSING'
            else:
                try:
                    res = fn(i)
                except Exception as e:  # noqa: BLE001
                    res = 'FAILED (%s)' % e
            if res.startswith(('FAILED', 'MISSING', 'SKIPPED')):
                bad += 1
            print('%-8s %-32s %s' % (kind, i, res), flush=True)
    print('%d problem(s)' % bad)


if __name__ == '__main__':
    main()
