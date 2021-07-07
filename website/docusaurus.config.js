const lightCodeTheme = require('prism-react-renderer/themes/github');
const darkCodeTheme = require('prism-react-renderer/themes/dracula');

/** @type {import('@docusaurus/types').DocusaurusConfig} */
module.exports = {
  title: 'wehoop',
  tagline: "The SportsDataverse's R Package for Women's Basketball Data.",
  url: 'https://wehoop.sportsdataverse.org',
  baseUrl: '/',
  onBrokenLinks: 'throw',
  onBrokenMarkdownLinks: 'warn',
  favicon: 'img/favicon.ico',
  organizationName: 'sportsdataverse', // Usually your GitHub org/user name.
  projectName: 'docusaurus', // Usually your repo name.
  themeConfig: {
    hideableSidebar: true,
    sidebarCollapsible: false,
    colorMode: {
      defaultMode: 'light',
      disableSwitch: false,
      respectPrefersColorScheme: true,
    },
    image: 'img/wehoop-gh.png',
    navbar: {
      hideOnScroll: true,
      title: 'wehoop',
      logo: {
        alt: 'wehoop Logo',
        src: 'img/logo.ico',
      },
      items: [
        {
          type: 'doc',
          docId: 'intro',
          position: 'left',
          label: 'Docs',
        },
        {
          label: 'Tutorials',
          position: 'left',
          items: [
            {
              href: '/blog/getting-started-wehoop',
              label: 'Getting Started',
              target: '_self',
            },
          ],
        },
        {
          label: 'News',
          to: 'CHANGELOG',
          position: 'left',
        },
        {
          label: 'SDV',
          position: 'left',
          items: [
            {
              href: 'https://sportsdataverse.org',
              label: 'SportsDataverse',
              target: '_self',
            },
            {
              label: 'Python Packages',
            },
            {
              label: 'cfbfastR-py',
              href: 'https://cfbfastR-py.sportsdataverse.org',
              target: '_self',
            },
            {
              label: 'hoopR-py',
              href: 'https://hoopR-py.sportsdataverse.org',
              target: '_self',
            },
            {
              label: 'wehoop-py',
              href: 'https://wehoop-py.sportsdataverse.org',
              target: '_self',
            },
            {
              label: 'R Packages',
            },
            {
              label: 'cfbfastR',
              href: 'https://saiemgilani.github.io/cfbfastR/',
              target: '_self',
            },
            {
              label: 'hoopR',
              href: 'https://saiemgilani.github.io/hoopR/',
              target: '_self',
            },
            {
              label: 'recruitR',
              href: 'https://saiemgilani.github.io/recruitR/',
              target: '_self',
            },
            {
              label: 'puntr',
              href: 'https://puntalytics.github.io/puntr/',
              target: '_self',
            },
            {
              label: 'gamezoneR',
              href: 'https://jacklich10.github.io/gamezoneR/',
              target: '_self',
            },
          ]
        },
        {
          href: 'https://github.com/saiemgilani/wehoop',
          label: 'GitHub',
          position: 'right',
        },
      ],
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'Docs',
          items: [
            {
              label: 'Docs',
              to: '/docs/intro',
            },
            {
              label: 'Tutorials',
              to: '/blog/getting-started-wehoop',
            },
          ],
        },
        {
          title: 'Community',
          items: [
            {
              label: 'Twitter (@SaiemGilani)',
              href: 'https://twitter.com/saiemgilani',
            },
            {
              label: 'Twitter (@hutchngo)',
              href: 'https://twitter.com/hutchngo',
            },
          ],
        },
        {
          title: 'More',
          items: [
            {
              label: 'GitHub',
              href: 'https://github.com/saiemgilani/wehoop',
            },
          ],
        },
      ],
      copyright: `Copyright © ${new Date().getFullYear()} <strong>wehoop</strong>, developed by <a href='https://twitter.com/saiemgilani'>Saiem Gilani</a> and <a href='https://twitter.com/hutchngo'>Geoff Hutchinson</a>, part of the <a href='https://sportsdataverse.org'>SportsDataverse</a>.`,
    },
    prism: {
      theme: lightCodeTheme,
      darkTheme: darkCodeTheme,
    },
  },
  presets: [
    [
      '@docusaurus/preset-classic',
      {
        docs: {
          sidebarPath: require.resolve('./sidebars.js'),
          // Please change this to your repo.
          editUrl:
            'https://github.com/saiemgilani/wehoop/edit/master/website/',
        },
        theme: {
          customCss: require.resolve('./src/css/custom.css'),
        },
      },
    ],
  ],
};
