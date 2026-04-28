<?php

namespace ChurchCRM\Plugins\RgpdConformite;

use ChurchCRM\Plugin\AbstractPlugin;

class RgpdConformitePlugin extends AbstractPlugin
{
    public function getId(): string
    {
        return 'rgpd-conformite';
    }

    public function getName(): string
    {
        return 'RGPD Compliance';
    }

    public function getDescription(): string
    {
        return 'GDPR / RGPD compliance toolkit for ChurchCRM.';
    }

    public function getVersion(): string
    {
        return '0.1.0';
    }

    public function boot(): void
    {
    }

    public function isConfigured(): bool
    {
        return true;
    }
}
